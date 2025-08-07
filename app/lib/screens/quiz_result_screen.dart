import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class QuizResultsScreen extends StatelessWidget {
  final Quiz quiz;
  const QuizResultsScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final quizTakerRole = quiz.creatorRole == 'Panda' ? 'Penguin' : 'Panda';
    final myRole = quiz.creatorRole;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results', style: Theme.of(context).textTheme.headlineLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '"${quiz.title}"',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Final Score:',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${quiz.creatorScore}/${quiz.questions.length}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final question = quiz.questions[index];
                  final playerAnswer = quiz.playerAnswers?[index] ?? 'N/A';
                  final isCorrect = (quiz.creatorScore != null) ? quiz.playerAnswers![index] == question.correctAnswer : false; // This part depends on the validation logic

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Image.asset(
                        myRole == 'Panda'
                          ? 'assets/images/panda_avatar.png'
                          : 'assets/images/penguin_avatar.png',
                        width: 40,
                      ),
                      title: Text('Q${index + 1}: ${question.questionText}'),
                      subtitle: Text(
                        'Their Answer: $playerAnswer',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}