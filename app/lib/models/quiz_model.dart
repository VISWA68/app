import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single question in a quiz
class Question {
  final String type;
  final String questionText;
  final String? correctAnswer;
  final List<String>? options;

  Question({
    required this.type,
    required this.questionText,
    this.correctAnswer,
    this.options,
  });

  // Convert a Question object to a Firestore map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'options': options,
    };
  }

  // Create a Question object from a Firestore map
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      type: map['type'],
      questionText: map['questionText'],
      correctAnswer: map['correctAnswer'],
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
    );
  }
}

// Represents a complete quiz
class Quiz {
  final String id;
  final String creatorRole;
  final String title;
  final int validityDays;
  final String status;
  final List<Question> questions;
  final List<String>? playerAnswers;
  final int? creatorScore;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.creatorRole,
    required this.title,
    required this.validityDays,
    required this.status,
    required this.questions,
    this.playerAnswers,
    this.creatorScore,
    required this.createdAt,
  });

  // Convert a Quiz object to a Firestore map
  Map<String, dynamic> toMap() {
    return {
      'creatorRole': creatorRole,
      'title': title,
      'validityDays': validityDays,
      'status': status,
      'questions': questions.map((q) => q.toMap()).toList(),
      'playerAnswers': playerAnswers,
      'creatorScore': creatorScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a Quiz object from a Firestore document
  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      creatorRole: data['creatorRole'],
      title: data['title'],
      validityDays: data['validityDays'],
      status: data['status'],
      questions: (data['questions'] as List)
          .map((q) => Question.fromMap(q))
          .toList(),
      playerAnswers: data['playerAnswers'] != null
          ? List<String>.from(data['playerAnswers'])
          : null,
      creatorScore: data['creatorScore'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
