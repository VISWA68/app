import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../utils/database_helper.dart';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Quiz> _pendingQuizzes = [];
  List<Quiz> _completedQuizzes = []; // New list
  List<Quiz> _myQuizzes = [];
  String? userRole;

  List<Quiz> get pendingQuizzes => _pendingQuizzes;
  List<Quiz> get completedQuizzes => _completedQuizzes; // New getter
  List<Quiz> get myQuizzes => _myQuizzes;

  QuizProvider() {
    _loadUserRoleAndFetchQuizzes();
  }

  void _loadUserRoleAndFetchQuizzes() async {
    userRole = await DatabaseHelper().getCharacterChoice();
    if (userRole != null) {
      _fetchQuizzes(userRole!);
    }
  }

  void _fetchQuizzes(String userRole) {
    _firestore.collection('quizzes')
      .snapshots()
      .listen((snapshot) {
        final allQuizzes = snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
        
        _pendingQuizzes = allQuizzes.where((quiz) => quiz.status == 'pending' && quiz.creatorRole != userRole).toList();
        _completedQuizzes = allQuizzes.where((quiz) => quiz.playerAnswers != null && quiz.creatorRole != userRole).toList(); // Filter for quizzes you have taken
        _myQuizzes = allQuizzes.where((quiz) => quiz.creatorRole == userRole).toList();
        
        notifyListeners();
      });
  }

  Future<void> createQuiz({
    required String creatorRole,
    required String title,
    required int validityDays,
    required List<Map<String, dynamic>> questions,
  }) async {
    final quiz = Quiz(
      id: '',
      creatorRole: creatorRole,
      title: title,
      validityDays: validityDays,
      status: 'pending',
      questions: questions.map((q) => Question.fromMap(q)).toList(),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('quizzes').add(quiz.toMap());
  }

  Future<void> completeQuiz({
    required String quizId,
    required List<String> playerAnswers,
  }) async {
    await _firestore.collection('quizzes').doc(quizId).update({
      'status': 'completed',
      'playerAnswers': playerAnswers,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> validateQuiz({
    required String quizId,
    required int creatorScore,
  }) async {
    await _firestore.collection('quizzes').doc(quizId).update({
      'status': 'validated',
      'creatorScore': creatorScore,
    });
  }
}