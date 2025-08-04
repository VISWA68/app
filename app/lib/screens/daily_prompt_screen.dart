import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_prompt_provider.dart';
import '../utils/database_helper.dart';

class DailyPromptScreen extends StatefulWidget {
  const DailyPromptScreen({super.key});

  @override
  _DailyPromptScreenState createState() => _DailyPromptScreenState();
}

class _DailyPromptScreenState extends State<DailyPromptScreen> {
  final TextEditingController _textController = TextEditingController();
  String _userRole = 'Panda';
  String _otherUserRole = 'Penguin';

  final List<String> _hardcodedPrompts = [
    'A sweet memory I had of us today...',
    'I\'m looking forward to...',
    'A silly thing I thought about was...',
    'Something that made me smile was...',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final role = await DatabaseHelper().getCharacterChoice();
    if (mounted && role != null) {
      setState(() {
        _userRole = role;
        _otherUserRole = role == 'Panda' ? 'Penguin' : 'Panda';
      });
      // Start listening for prompts
      context.read<DailyPromptProvider>().startListeningForPrompts(
        _userRole,
        _otherUserRole,
      );
    }
  }

  void _sendPrompt() {
    if (_textController.text.isNotEmpty) {
      context.read<DailyPromptProvider>().sendMyPrompt(
        _userRole,
        _textController.text,
      );
      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your thought has been sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyPromptProvider = context.watch<DailyPromptProvider>();
    final bool canSendPrompt = !dailyPromptProvider.hasSentPrompt;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hey $_userRole',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (dailyPromptProvider.otherPersonPrompt != null)
                _buildOtherPersonThought(
                  context,
                  dailyPromptProvider.otherPersonPrompt!,
                )
              else
                _buildEmptyThoughtState(context, _otherUserRole),

              const SizedBox(height: 24),
              Text(
                'What do you want to tell your $_otherUserRole today?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                children: _hardcodedPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(prompt),
                    backgroundColor: canSendPrompt
                        ? Theme.of(context).cardColor
                        : Colors.grey[200],
                    labelStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: canSendPrompt
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                    onPressed: canSendPrompt
                        ? () {
                            _textController.text = prompt;
                          }
                        : null, // Disable the chip if the prompt has been sent
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _textController,
                readOnly: !canSendPrompt, // Make the text field read-only
                decoration: InputDecoration(
                  hintText: canSendPrompt
                      ? 'Share a sweet thought...'
                      : 'You have already sent your thought for today!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: canSendPrompt
                      ? Theme.of(context).cardColor
                      : Colors.grey[200],
                  contentPadding: const EdgeInsets.all(20),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: canSendPrompt
                    ? _sendPrompt
                    : null, // Disable the button
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  backgroundColor: canSendPrompt
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
                child: Text(
                  'Send a thought',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherPersonThought(BuildContext context, String message) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              _otherUserRole == 'Panda'
                  ? 'assets/images/panda_avatar.png'
                  : 'assets/images/penguin_avatar.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyThoughtState(BuildContext context, String otherUserRole) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              otherUserRole == 'Panda'
                  ? 'assets/images/panda_avatar.png'
                  : 'assets/images/penguin_avatar.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your $otherUserRole hasn\'t shared their daily thought yet!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
