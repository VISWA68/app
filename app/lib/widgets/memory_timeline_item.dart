import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory_model.dart';

class MemoryTimelineItem extends StatelessWidget {
  final Memory memory;
  final bool isFirst;
  final bool isLast;
  final String? userRole;

  const MemoryTimelineItem({
    super.key,
    required this.memory,
    required this.isFirst,
    required this.isLast,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = memory.author == userRole;
    final authorEmoji = memory.author == 'Panda' ? '🐼' : '🐧';
    final partnerEmoji = memory.author == 'Panda' ? '🐧' : '🐼';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and avatar
          _buildTimelineIndicator(context, authorEmoji, isCurrentUser),
          const SizedBox(width: 16),
          
          // Memory content
          Expanded(
            child: _buildMemoryCard(context, isCurrentUser, partnerEmoji),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(BuildContext context, String emoji, bool isCurrentUser) {
    return Column(
      children: [
        // Timeline line (top)
        if (!isFirst)
          Container(
            width: 2,
            height: 20,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ),
        
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        
        // Timeline line (bottom)
        if (!isLast)
          Container(
            width: 2,
            height: 20,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ),
      ],
    );
  }

  Widget _buildMemoryCard(BuildContext context, bool isCurrentUser, String partnerEmoji) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author and timestamp
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  memory.author,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser 
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCurrentUser ? '(You)' : '(${memory.author})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(memory.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Images
          if (memory.photoUrls != null && memory.photoUrls!.isNotEmpty)
            _buildImageSection(context),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                  ),
                ),
                
                // Location info if available
                if (memory.latitude != null && memory.longitude != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Location saved',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Interaction row
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Heart reaction
                    InkWell(
                      onTap: () => _showReaction(context, partnerEmoji),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💕', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              'Love',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Share button
                    InkWell(
                      onTap: () => _shareMemory(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Share',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final images = memory.photoUrls!;
    
    if (images.length == 1) {
      return _buildSingleImage(context, images.first);
    } else {
      return _buildMultipleImages(context, images);
    }
  }

  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    return Container(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 250,
              color: Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Image not available'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMultipleImages(BuildContext context, List<String> images) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              children: [
                ClipRRect(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Image not available'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Image counter
                if (images.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  void _showReaction(BuildContext context, String partnerEmoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(partnerEmoji),
            const SizedBox(width: 8),
            const Text('Loved this memory! 💕'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _shareMemory(BuildContext context) {
    // Here you would implement actual sharing functionality
    // For now, just show a cute message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(memory.author == 'Panda' ? '🐼' : '🐧'),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Sharing this beautiful memory... 💕'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}