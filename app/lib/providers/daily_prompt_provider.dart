import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyPromptProvider with ChangeNotifier {
  String? _otherPersonPrompt;
  bool _hasSentPrompt = false;
  String? get otherPersonPrompt => _otherPersonPrompt;
  bool get hasSentPrompt => _hasSentPrompt;

  // This will listen for the other person's prompt and check your own
  void startListeningForPrompts(String myRole, String otherPersonRole) {
    _listenForOtherPrompt(otherPersonRole);
    _checkMyPromptStatus(myRole);
  }

  void _listenForOtherPrompt(String otherPersonRole) {
    final otherUserDocId = '${otherPersonRole.toLowerCase()}_prompt';

    FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc(otherUserDocId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // Convert the Firestore Timestamp to a DateTime
        final promptTimestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        
        // Check if the prompt is from today (IST timezone)
        if (promptTimestamp != null &&
            DateFormat('yyyy-MM-dd').format(promptTimestamp.toLocal()) ==
            DateFormat('yyyy-MM-dd').format(now.toLocal())) {
          _otherPersonPrompt = data['prompt'] as String?;
        } else {
          // The prompt is from a previous day, so clear it
          _otherPersonPrompt = null;
        }
      } else {
        _otherPersonPrompt = null;
      }
      notifyListeners();
    });
  }

  // Check your own prompt status to disable the button
  void _checkMyPromptStatus(String myRole) {
    final myUserDocId = '${myRole.toLowerCase()}_prompt';

    FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc(myUserDocId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        final promptTimestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (promptTimestamp != null &&
            DateFormat('yyyy-MM-dd').format(promptTimestamp.toLocal()) ==
            DateFormat('yyyy-MM-dd').format(now.toLocal())) {
          // You have already sent a prompt today
          _hasSentPrompt = true;
        } else {
          _hasSentPrompt = false;
        }
      } else {
        _hasSentPrompt = false;
      }
      notifyListeners();
    });
  }

  Future<void> sendMyPrompt(String myRole, String message) async {
    final myUserDocId = '${myRole.toLowerCase()}_prompt';
    await FirebaseFirestore.instance.collection('dailyPrompts').doc(myUserDocId).set({
      'senderId': myRole,
      'senderAvatar': myRole.toLowerCase(),
      'prompt': message,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // After sending, we don't need to manually update `_hasSentPrompt` here
    // because the `_checkMyPromptStatus` stream will automatically do it for us.
  }
}