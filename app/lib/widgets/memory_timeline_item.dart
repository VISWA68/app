import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/place_model.dart';

class MemoryTimelineItem extends StatelessWidget {
  final Place place;
  final bool isFirst;
  final bool isLast;

  const MemoryTimelineItem({
    Key? key, 
    required this.place, 
    this.isFirst = false, 
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the author is Panda or Penguin
    final bool isPanda = place.authorRole == 'Panda';
    
    return TimelineTile(
      alignment: TimelineAlign.center,
      isFirst: isFirst,
      isLast: isLast,
      endChild: isPanda ? _buildMemoryCard(context, isPanda) : null,
      startChild: isPanda ? null : _buildMemoryCard(context, isPanda),
      indicatorStyle: IndicatorStyle(
        width: 30,
        height: 30,
        indicator: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Center(
            child: Icon(
              isPanda ? Icons.camera_alt : Icons.favorite,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
      beforeLineStyle: LineStyle(color: Colors.grey.shade300),
      afterLineStyle: LineStyle(color: Colors.grey.shade300),
    );
  }

  Widget _buildMemoryCard(BuildContext context, bool isPanda) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Panda or Penguin Avatar
                Image.asset(
                  isPanda ? 'assets/images/panda_avatar.png' : 'assets/images/penguin_avatar.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 8),
                Text(
                  isPanda ? 'You' : 'Her',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (place.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: place.imageUrls.first,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              place.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              place.timestamp != null 
                  ? '${place.timestamp!.day}/${place.timestamp!.month}/${place.timestamp!.year}'
                  : 'No date',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}