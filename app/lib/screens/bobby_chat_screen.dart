import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bobby_chat_provider.dart';
import '../models/chat_message.dart';

class BobbyChatScreen extends StatefulWidget {
  final String userRole;
  const BobbyChatScreen({super.key, required this.userRole});

  @override
  State<BobbyChatScreen> createState() => _BobbyChatScreenState();
}

class _BobbyChatScreenState extends State<BobbyChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      context.read<BobbyChatProvider>().sendMessage(_textController.text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    _scrollToBottom();
    final bobbyChatProvider = context.watch<BobbyChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/bobby_avatar.png'),
              radius: 20,
            ),
            SizedBox(width: 8),
            Text('Bobby'),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              image: const DecorationImage(
                image: AssetImage('assets/images/paw_print.png'),
                repeat: ImageRepeat.repeat,
                opacity: 0.08,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: bobbyChatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = bobbyChatProvider.messages[index];
                      return _buildMessageBubble(context, message);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8.0,
                  ),
                  child: _buildMessageInput(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isMe = message.sender == widget.userRole;
    final isBobby = message.sender == 'Bobby';

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Show Bobby's avatar on the left
        if (isBobby) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/bobby_avatar.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
        ],
        // The chat bubble itself
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.8)
                : isBobby
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
            ),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isMe ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              widget.userRole == 'Panda'
                  ? 'assets/images/panda_avatar.png'
                  : 'assets/images/penguin_avatar.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Talk to Bobby...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'bobby_send_button',
            onPressed: _sendMessage,
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Image.asset(
              'assets/images/paw_icon.png',
              width: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
