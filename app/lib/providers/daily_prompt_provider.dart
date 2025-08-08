import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyPromptProvider with ChangeNotifier {
  String? _otherPersonPrompt;
  bool _hasSentPrompt = false;
  String? _myMoodEmoji;
  String? _myMoodText;
  String? _myMoodReason;
  String? _otherPersonMoodEmoji;
  String? _otherPersonMoodText;
  String? _otherPersonMoodReason;

  String? get otherPersonPrompt => _otherPersonPrompt;
  bool get hasSentPrompt => _hasSentPrompt;
  String? get myMoodEmoji => _myMoodEmoji;
  String? get myMoodText => _myMoodText;
  String? get myMoodReason => _myMoodReason;
  String? get otherPersonMoodEmoji => _otherPersonMoodEmoji;
  String? get otherPersonMoodText => _otherPersonMoodText;
  String? get otherPersonMoodReason => _otherPersonMoodReason;

  void startListeningForPrompts(String myRole, String otherPersonRole) {
    _listenForOtherPrompt(otherPersonRole);
    _checkMyPromptStatus(myRole);
    _listenForMoods(myRole, otherPersonRole);
  }

  void _listenForMoods(String myRole, String otherPersonRole) {
    final myMoodDocId = myRole.toLowerCase();
    final otherMoodDocId = otherPersonRole.toLowerCase();

    // Listen to my mood to display in the UI
    FirebaseFirestore.instance.collection('moods').doc(myMoodDocId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _myMoodEmoji = data['emoji'];
        _myMoodText = data['moodText'];
        _myMoodReason = data['reason'];
        notifyListeners();
      }
    });

    // Listen to the other person's mood
    FirebaseFirestore.instance.collection('moods').doc(otherMoodDocId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _otherPersonMoodEmoji = data['emoji'];
        _otherPersonMoodText = data['moodText'];
        _otherPersonMoodReason = data['reason'];
        notifyListeners();
      }
    });
  }

  Future<void> updateMyMood({
    required String myRole,
    required String emoji,
    required String moodText,
    String? reason,
  }) async {
    final myMoodDocId = myRole.toLowerCase();
    await FirebaseFirestore.instance.collection('moods').doc(myMoodDocId).set({
      'emoji': emoji,
      'moodText': moodText,
      'reason': reason,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenForOtherPrompt(String otherPersonRole) {
    FirebaseFirestore.instance.collection('prompts').doc(otherPersonRole.toLowerCase()).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _otherPersonPrompt = data['prompt'];
        notifyListeners();
      }
    });
  }

  Future<void> _checkMyPromptStatus(String myRole) async {
    final doc = await FirebaseFirestore.instance.collection('prompts').doc(myRole.toLowerCase()).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      _hasSentPrompt = data['hasSent'] ?? false;
      notifyListeners();
    }
  }

  Future<void> sendMyPrompt(String myRole, String prompt) async {
    await FirebaseFirestore.instance.collection('prompts').doc(myRole.toLowerCase()).set({
      'prompt': prompt,
      'hasSent': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _hasSentPrompt = true;
    notifyListeners();
  }
}