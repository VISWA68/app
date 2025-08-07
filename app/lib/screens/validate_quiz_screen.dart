import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_model.dart';

class ValidateQuizScreen extends StatefulWidget {
  final Quiz quiz;
  const ValidateQuizScreen({super.key, required this.quiz});

  @override
  _ValidateQuizScreenState createState() => _ValidateQuizScreenState();
}

class _ValidateQuizScreenState extends State<ValidateQuizScreen> {
  late List<bool> _isCorrect;
  late int _finalScore;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isCorrect = List.generate(widget.quiz.questions.length, (index) => false);
    _calculateScore();
  }

  void _calculateScore() {
    _finalScore = _isCorrect.where((element) => element).length;
  }

  Future<void> _submitScore() async {
    setState(() {
      _isSaving = true;
    });
    await context.read<QuizProvider>().validateQuiz(
      quizId: widget.quiz.id,
      creatorScore: _finalScore,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizTakerRole = widget.quiz.creatorRole == 'Panda'
        ? 'Penguin'
        : 'Panda';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Validate "${widget.quiz.title}"',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your $quizTakerRole has completed the quiz! Here are the answers:',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.quiz.questions.length,
                      itemBuilder: (context, index) {
                        final question = widget.quiz.questions[index];
                        final playerAnswer =
                            widget.quiz.playerAnswers?[index] ?? 'N/A';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Q${index + 1}: ${question.questionText}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Their answer: $playerAnswer',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Mark as correct:'),
                                    Checkbox(
                                      value: _isCorrect[index],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isCorrect[index] = value ?? false;
                                          _calculateScore();
                                        });
                                      },
                                      activeColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _submitScore,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        'Submit Score: $_finalScore',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
