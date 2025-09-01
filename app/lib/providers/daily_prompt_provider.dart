import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class DailyPromptProvider with ChangeNotifier {
  String? _currentPrompt;
  String? _longPromptDialog;
  String? _myLastPrompt; // Add this to store user's last sent prompt
  String? _myMoodEmoji;
  String? _myMoodText;
  String? _myMoodReason;
  String? _otherPersonMoodEmoji;
  String? _otherPersonMoodText;
  String? _otherPersonMoodReason;
  String? _otherPersonPrompt;

  final NotificationService _notificationService = NotificationService();

  String? get currentPrompt => _currentPrompt;
  String? get longPromptDialog => _longPromptDialog;
  String? get myLastPrompt =>
      _myLastPrompt; // Add getter for user's last prompt
  String? get myMoodEmoji => _myMoodEmoji;
  String? get myMoodText => _myMoodText;
  String? get myMoodReason => _myMoodReason;
  String? get otherPersonMoodEmoji => _otherPersonMoodEmoji;
  String? get otherPersonMoodText => _otherPersonMoodText;
  String? get otherPersonMoodReason => _otherPersonMoodReason;
  String? get otherPersonPrompt => _otherPersonPrompt;

  void setPrompt(String prompt) {
    _currentPrompt = prompt;
    notifyListeners();
  }

  void showLongPromptDialog(String prompt) {
    _longPromptDialog = prompt;
    notifyListeners();
  }

  void clearLongPromptDialog() {
    _longPromptDialog = null;
    notifyListeners();
  }

  void startListeningForPrompts(String myRole, String otherPersonRole) {
    _listenForOtherPrompt(otherPersonRole);
    _listenForMyPrompt(myRole); // Listen for user's own prompts
    _listenForMoods(myRole, otherPersonRole);
  }

  void _listenForOtherPrompt(String otherPersonRole) {
    FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc('${otherPersonRole.toLowerCase()}_prompt')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            final promptTimestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final now = DateTime.now();

            if (promptTimestamp != null &&
                now.difference(promptTimestamp).inHours < 24) {
              _otherPersonPrompt = data['prompt'];
            } else {
              _otherPersonPrompt = null;
            }
            notifyListeners();
          } else {
            _otherPersonPrompt = null;
            notifyListeners();
          }
        });
  }

  // Add method to listen for user's own prompts
  void _listenForMyPrompt(String myRole) {
    FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc('${myRole.toLowerCase()}_prompt')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            final promptTimestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final now = DateTime.now();

            if (promptTimestamp != null &&
                now.difference(promptTimestamp).inHours < 24) {
              _myLastPrompt = data['prompt'];
            } else {
              _myLastPrompt = null;
            }
            notifyListeners();
          } else {
            _myLastPrompt = null;
            notifyListeners();
          }
        });
  }

  void _listenForMoods(String myRole, String otherPersonRole) {
    final myMoodDocId = myRole.toLowerCase();
    final otherMoodDocId = otherPersonRole.toLowerCase();

    FirebaseFirestore.instance
        .collection('moods')
        .doc(myMoodDocId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            _myMoodEmoji = data['emoji'];
            _myMoodText = data['moodText'];
            _myMoodReason = data['reason'];
            notifyListeners();
          }
        });

    FirebaseFirestore.instance
        .collection('moods')
        .doc(otherMoodDocId)
        .snapshots()
        .listen((snapshot) {
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

    final otherUser = myRole == 'Panda' ? 'Penguin' : 'Panda';
    await _notificationService.notifyMoodUpdate(otherUser, moodText);
  }

  Future<void> sendMyPrompt(String myRole, String prompt) async {
    final myUserDocId = '${myRole.toLowerCase()}_prompt';
    await FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc(myUserDocId)
        .set({
          'senderId': myRole,
          'senderAvatar': myRole.toLowerCase(),
          'prompt': prompt,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Remove the _hasSentPrompt = true; line since we're removing the lock
    notifyListeners();

    final otherUser = myRole == 'Panda' ? 'Penguin' : 'Panda';
    await _notificationService.notifyDailyPromptUpdate(otherUser);
  }

  void updateOtherPersonPrompt(String prompt) {
    _otherPersonPrompt = prompt;
    notifyListeners();
  }
}
