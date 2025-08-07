import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  _QuizPlayScreenState createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final List<String> _playerAnswers = [];
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _playerAnswers.addAll(List.filled(widget.quiz.questions.length, ''));
  }

  void _submitAnswer(String answer) {
    setState(() {
      _playerAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz() async {
    // Save answers to the provider
    await context.read<QuizProvider>().completeQuiz(
      quizId: widget.quiz.id,
      playerAnswers: _playerAnswers,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizTakerRole = widget.quiz.creatorRole == 'Panda' ? 'Penguin' : 'Panda';
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final isMCQ = currentQuestion.type == 'MCQ';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  currentQuestion.questionText,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isMCQ) ...[
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: currentQuestion.options!.length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options![index];
                    final isSelected = _playerAnswers[_currentQuestionIndex] == option;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () => _submitAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.secondary.withOpacity(0.8)
                              : Theme.of(context).cardColor,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: Text(option),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Fill-in-the-blank text field
              TextField(
                onChanged: (value) => _submitAnswer(value),
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentQuestionIndex < widget.quiz.questions.length - 1
                    ? 'Next Question'
                    : 'Finish Quiz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}