import 'package:app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/daily_prompt_provider.dart';
import '../utils/database_helper.dart';
import '../widgets/draggable_mood_button.dart';

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

  final Map<String, String> _moods = {
    'Happy': '😀',
    'Sad': '😥',
    'Excited': '🤩',
    'Relaxed': '😌',
    'Horny': '😈',
    'Angry': '😡',
    'Tired': '😴',
    'Bored': '🥱',
    'Romance': '🥰',
    'Stressed': '🤯',
    'Flirty': '😉',
    'Silly': '😜',
  };

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

  void _showMoodOptionsDialog() {
    final myAvatar = _userRole == 'Panda'
        ? 'assets/images/panda_avatar.png'
        : 'assets/images/penguin_avatar.png';
    final partnerAvatar = _userRole == 'Panda'
        ? 'assets/images/penguin_avatar.png'
        : 'assets/images/panda_avatar.png';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Center(
          child: Text(
            'Mood Makes Sense',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20, // horizontal gap
          runSpacing: 20, // vertical gap (if wrapping)
          children: [
            _buildMoodOptionCard(
              context,
              avatarPath: myAvatar,
              label: 'Update My Mood',
              onTap: () {
                Navigator.pop(context);
                _showUpdateMoodDialog();
              },
            ),
            _buildMoodOptionCard(
              context,
              avatarPath: partnerAvatar,
              label:
                  'View ${_userRole == "Panda" ? "Penguin\'s" : "Panda\'s"} Mood',
              onTap: () {
                Navigator.pop(context);
                _showPartnerMoodPopUp();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOptionCard(
    BuildContext context, {
    required String avatarPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // fixed smaller width so both fit in a row
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(avatarPath, width: 50, height: 50),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateMoodDialog() {
    String? selectedMood;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: const Center(
          child: Text(
            'How are you feeling?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: _moods.keys.map((moodName) {
                      final isSelected = selectedMood == moodName;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedMood = moodName);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.15)
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _moods[moodName]!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                moodName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Add a reason (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
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
              if (selectedMood != null) {
                context.read<DailyPromptProvider>().updateMyMood(
                  myRole: _userRole,
                  emoji: _moods[selectedMood]!,
                  moodText: selectedMood!,
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a mood.')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPartnerMoodPopUp() {
    final dailyPromptProvider = context.read<DailyPromptProvider>();
    final partnerMoodEmoji = dailyPromptProvider.otherPersonMoodEmoji;
    final partnerMoodText = dailyPromptProvider.otherPersonMoodText;
    final partnerMoodReason = dailyPromptProvider.otherPersonMoodReason;

    final partnerAvatar = _userRole == 'Panda'
        ? 'assets/images/penguin_avatar.png'
        : 'assets/images/panda_avatar.png';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage(partnerAvatar),
            ),
            const SizedBox(height: 8),
            Text(
              '${_userRole == "Panda" ? "Penguin" : "Panda"} is feeling...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: partnerMoodEmoji != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(partnerMoodEmoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(
                    partnerMoodText ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (partnerMoodReason != null &&
                      partnerMoodReason.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '"$partnerMoodReason"',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Your partner has not set their mood yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtCard(
    BuildContext context,
    String message,
    String role, {
    bool isMyThought = false,
  }) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              role == 'Panda'
                  ? 'assets/images/panda_avatar.png'
                  : 'assets/images/penguin_avatar.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMyThought)
                    Text(
                      'Your last thought:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isMyThought) const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyLarge),
                ],
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

  @override
  Widget build(BuildContext context) {
    final dailyPromptProvider = context.watch<DailyPromptProvider>();
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final totalBottomPadding = 60 + bottomSafeArea;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
        title: Text(
          'Hey $_userRole',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: totalBottomPadding),
              child: Column(
                children: [
                  // Display partner's thought
                  if (dailyPromptProvider.otherPersonPrompt != null)
                    _buildThoughtCard(
                      context,
                      dailyPromptProvider.otherPersonPrompt!,
                      _otherUserRole,
                    )
                  else
                    _buildEmptyThoughtState(context, _otherUserRole),

                  const SizedBox(height: 16),

                  // Display user's last thought if it exists
                  if (dailyPromptProvider.myLastPrompt != null)
                    _buildThoughtCard(
                      context,
                      dailyPromptProvider.myLastPrompt!,
                      _userRole,
                      isMyThought: true,
                    ),

                  const SizedBox(height: 24),
                  Text(
                    dailyPromptProvider.myLastPrompt != null
                        ? 'Want to share another thought with your $_otherUserRole?'
                        : 'What do you want to tell your $_otherUserRole today?',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: _hardcodedPrompts.map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        backgroundColor: Theme.of(context).cardColor,
                        labelStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Theme.of(context).primaryColor),
                        onPressed: () {
                          _textController.text = prompt;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Share a sweet thought...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _sendPrompt,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: Text(
                      dailyPromptProvider.myLastPrompt != null
                          ? 'Send another thought'
                          : 'Send a thought',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableMoodButton(
            onPressed: _showMoodOptionsDialog,
            icon: Icons.mood,
          ),
        ],
      ),
    );
  }
}
