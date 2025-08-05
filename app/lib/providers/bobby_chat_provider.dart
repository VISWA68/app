import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/chat_message.dart';

class BobbyChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  late final GenerativeModel _model;
  late final String _userRole;

  BobbyChatProvider(String userRole) {
    _userRole = userRole;
    _initGeminiModel();
    _listenToChatHistory();
  }

  void _initGeminiModel() {
    const modelName = 'gemini-2.5-flash';
    _model = FirebaseAI.googleAI().generativeModel(model: modelName);
  }

  void _listenToChatHistory() async {
    final userDocId = _userRole.toLowerCase();

    // Check if the chat needs to be refreshed
    await _checkForDailyRefresh();

    // Now, listen to the chat history for the day
    _firestore
        .collection('bobby_chat_history')
        .doc(userDocId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            final messagesData = data['messages'] as List<dynamic>? ?? [];
            _messages = messagesData
                .map((e) => ChatMessage.fromFirestore(e))
                .toList();
          } else {
            _messages = [];
          }
          notifyListeners();
        });
  }

  Future<void> _checkForDailyRefresh() async {
    final sharedContextDoc = _firestore
        .collection('bobby_shared_context')
        .doc('daily_log');
    final docSnapshot = await sharedContextDoc.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final lastUpdated = (docSnapshot.data()?['lastUpdated'] as Timestamp?)
          ?.toDate();
      final now = DateTime.now();

      // Check if the last update was on a previous day
      if (lastUpdated != null && now.difference(lastUpdated).inHours >= 24) {
        // If it's a new day, clear all chat history
        await _clearAllChatHistory();
      }
    }
  }

  Future<void> _clearAllChatHistory() async {
    final sharedContextDoc = _firestore
        .collection('bobby_shared_context')
        .doc('daily_log');
    final pandaHistoryDoc = _firestore
        .collection('bobby_chat_history')
        .doc('panda');
    final penguinHistoryDoc = _firestore
        .collection('bobby_chat_history')
        .doc('penguin');

    await Future.wait([
      sharedContextDoc.delete(),
      pandaHistoryDoc.delete(),
      penguinHistoryDoc.delete(),
    ]);
  }

  Future<void> sendMessage(String message) async {
    final myMessage = ChatMessage(
      sender: _userRole,
      text: message,
      timestamp: DateTime.now(),
    );

    final userDocId = _userRole.toLowerCase();

    await _firestore.collection('bobby_chat_history').doc(userDocId).set({
      'messages': FieldValue.arrayUnion([myMessage.toFirestore()]),
    }, SetOptions(merge: true));

    final sharedContextDoc = await _firestore
        .collection('bobby_shared_context')
        .doc('daily_log')
        .get();
    final sharedMessages =
        (sharedContextDoc.data()?['messages'] as List<dynamic>? ?? [])
            .map((e) => ChatMessage.fromFirestore(e))
            .toList();

    final promptWithPersona = [
      Content.text(
        'You are Bobby, a cute Labrador acting as a relationship confidant for Viswa(Panda) and Suba(Penguin), their chats with you are private with other and only you know everything so give response based on the user. Your responses should be helpful and include dog sounds like "Woof!", "Bow wow!", and other dog sounds". Do not identify as an AI, keep the responses short and crisp.',
      ),
      ...sharedMessages
          .map((m) => Content.text('${m.sender}: ${m.text}'))
          .toList(),
      Content.text('My message is: "$message"'),
    ];

    try {
      final response = await _model.generateContent(promptWithPersona);
      final bobbyText = response.text ?? 'Woof! I didn\'t quite get that.';

      final bobbyMessage = ChatMessage(
        sender: 'Bobby',
        text: bobbyText,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('bobby_chat_history').doc(userDocId).set({
        'messages': FieldValue.arrayUnion([bobbyMessage.toFirestore()]),
      }, SetOptions(merge: true));

      await _firestore.collection('bobby_shared_context').doc('daily_log').set({
        'messages': FieldValue.arrayUnion([
          myMessage.toFirestore(),
          bobbyMessage.toFirestore(),
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error calling Gemini API: $e');
    }
  }
}
