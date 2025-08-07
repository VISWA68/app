import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../utils/database_helper.dart';
import '../models/quiz_model.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleController = TextEditingController();
  final _validityController = TextEditingController();
  final List<Question> _questions = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final role = await DatabaseHelper().getCharacterChoice();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  void _addQuestion() {
    final questionTextController = TextEditingController();
    String questionType = 'MCQ';
    final List<String> options = [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Add a Question',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionTextController,
                      decoration: const InputDecoration(
                        labelText: 'Your Question',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      value: questionType,
                      items: const [
                        DropdownMenuItem(
                          value: 'MCQ',
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: 'FILL_IN_THE_BLANK',
                          child: Text('Fill in the Blank'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => questionType = value.toString());
                      },
                    ),
                    if (questionType == 'MCQ') ...[
                      const SizedBox(height: 16),
                      for (var i = 0; i < options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Option ${i + 1}: ${options[i]}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => options.removeAt(i)),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final optionController = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('New Option'),
                              content: TextField(controller: optionController),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => {
                                    setState(
                                      () => options.add(optionController.text),
                                    ),
                                    Navigator.pop(context),
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionTextController.text.isNotEmpty &&
                  (questionType != 'MCQ' || options.isNotEmpty)) {
                setState(() {
                  _questions.add(
                    Question(
                      type: questionType,
                      questionText: questionTextController.text,
                      correctAnswer:
                          null, // Now always null, as per your request
                      options: options.isNotEmpty ? options : null,
                    ),
                  );
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields!')),
                );
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveQuiz() {
    if (_titleController.text.isEmpty ||
        _validityController.text.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all fields and add at least one question.',
          ),
        ),
      );
      return;
    }
    context.read<QuizProvider>().createQuiz(
      creatorRole: _userRole!,
      title: _titleController.text,
      validityDays: int.parse(_validityController.text),
      questions: _questions.map((q) => q.toMap()).toList(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final creatorAvatar = _userRole == 'Panda'
        ? 'assets/images/panda_avatar.png'
        : 'assets/images/penguin_avatar.png';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Quiz',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset(creatorAvatar, width: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz by $_userRole',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Quiz Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _validityController,
                          decoration: const InputDecoration(
                            labelText: 'Validity (days)',
                            hintText: 'e.g., 3',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_questions.isNotEmpty) ...[
                Text(
                  'Questions:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(question.questionText),
                        subtitle: Text('Type: ${question.type}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add a Question'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveQuiz,
                icon: const Icon(Icons.check),
                label: const Text('Save Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
