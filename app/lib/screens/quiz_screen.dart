import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_model.dart';
import 'create_quiz_screen.dart';
import 'validate_quiz_screen.dart';
import 'quiz_play_screen.dart'; // Import this
import 'quiz_result_screen.dart'; // Import this

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final userRole = quizProvider.userRole;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Quiz Time!',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelStyle: Theme.of(context).textTheme.titleMedium,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'My Quizzes'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildPendingQuizzes(quizProvider, userRole),
              _buildCompletedQuizzes(quizProvider, userRole),
              _buildMyQuizzes(quizProvider, userRole),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 76.0 + bottomSafeArea),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateQuizScreen(),
                    ),
                  );
                },
                label: const Text('Create Quiz'),
                icon: const Icon(Icons.add),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingQuizzes(QuizProvider quizProvider, String? userRole) {
    if (quizProvider.pendingQuizzes.isEmpty) {
      return Center(
        child: Text(
          'No quizzes to complete!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      itemCount: quizProvider.pendingQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizProvider.pendingQuizzes[index];
        final remainingDays =
            quiz.validityDays -
            DateTime.now().difference(quiz.createdAt).inDays;
        return _buildQuizCard(
          quiz: quiz,
          title: quiz.title,
          subtitle: 'Time left: $remainingDays days',
          buttonText: 'Start Quiz',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizPlayScreen(quiz: quiz),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedQuizzes(QuizProvider quizProvider, String? userRole) {
    final completedQuizzes = quizProvider.completedQuizzes;

    if (completedQuizzes.isEmpty) {
      return Center(
        child: Text(
          'You haven\'t completed any quizzes yet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: completedQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = completedQuizzes[index];
        String subtitle;
        String buttonText;
        VoidCallback onPressed;
        Color cardColor;

        if (quiz.status == 'validated') {
          subtitle = 'Score: ${quiz.creatorScore}/${quiz.questions.length}';
          buttonText = 'View Results';
          onPressed = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizResultsScreen(quiz: quiz),
              ),
            );
          };
          cardColor = Colors.green.withOpacity(0.1);
        } else {
          subtitle = 'Awaiting creator\'s validation...';
          buttonText = 'View Details';
          onPressed = () {
            // This is for viewing the quiz details without playing it
          };
          cardColor = Colors.orange.withOpacity(0.1);
        }

        return _buildQuizCard(
          quiz: quiz,
          title: quiz.title,
          subtitle: subtitle,
          buttonText: buttonText,
          onPressed: onPressed,
          cardColor: cardColor,
        );
      },
    );
  }

  Widget _buildMyQuizzes(QuizProvider quizProvider, String? userRole) {
    final myQuizzes = quizProvider.myQuizzes;
    if (myQuizzes.isEmpty) {
      return Center(
        child: Text(
          'You haven\'t created any quizzes yet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: myQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = myQuizzes[index];
        String subtitle;
        String buttonText;
        VoidCallback onPressed;
        Color cardColor;

        if (quiz.status == 'completed') {
          subtitle = 'Awaiting your validation!';
          buttonText = 'Validate';
          onPressed = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ValidateQuizScreen(quiz: quiz),
              ),
            );
          };
          cardColor = Colors.orange.withOpacity(0.1);
        } else if (quiz.status == 'validated') {
          subtitle = 'Score: ${quiz.creatorScore}/${quiz.questions.length}';
          buttonText = 'View Results';
          onPressed = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizResultsScreen(quiz: quiz),
              ),
            );
          };
          cardColor = Colors.green.withOpacity(0.1);
        } else {
          final remainingDays =
              quiz.validityDays -
              DateTime.now().difference(quiz.createdAt).inDays;
          subtitle = 'Time remaining: $remainingDays days';
          buttonText = 'View';
          onPressed = () {
            // This is for viewing the quiz details without playing it
          };
          cardColor = Theme.of(context).cardColor;
        }

        return _buildQuizCard(
          quiz: quiz,
          title: quiz.title,
          subtitle: subtitle,
          buttonText: buttonText,
          onPressed: onPressed,
          cardColor: cardColor,
        );
      },
    );
  }

  Widget _buildQuizCard({
    required Quiz quiz,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    Color? cardColor,
  }) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Image.asset(
          quiz.creatorRole == 'Panda'
              ? 'assets/images/panda_avatar.png'
              : 'assets/images/penguin_avatar.png',
          width: 40,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(buttonText),
        ),
      ),
    );
  }
}
