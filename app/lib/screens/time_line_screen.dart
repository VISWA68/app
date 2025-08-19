import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/memory_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/memory_timeline_item.dart';
import 'add_place_screen.dart';
import 'capture_image_screen.dart';
import 'profile_screen.dart';

class TimeLineScreen extends StatefulWidget {
  @override
  _TimeLineScreenState createState() => _TimeLineScreenState();
}

class _TimeLineScreenState extends State<TimeLineScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MemoryProvider>().fetchMemories());
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = context.watch<MemoryProvider>();
    final mapProvider = context.watch<MapProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Our Little World',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: mapProvider.places.isEmpty
          ? _buildEmptyState()
          : _buildTimeline(mapProvider.places),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Memories Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start creating memories by adding places or capturing images!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> places) {
    // Sort places by timestamp (newest first)
    final sortedPlaces = List.from(places);
    sortedPlaces.sort((a, b) {
      final aTime = a.timestamp ?? DateTime(1970);
      final bTime = b.timestamp ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: sortedPlaces.length,
      itemBuilder: (context, index) {
        final place = sortedPlaces[index];
        return MemoryTimelineItem(
          place: place,
          isFirst: index == 0,
          isLast: index == sortedPlaces.length - 1,
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Add Place Button
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton(
            heroTag: 'add_place',
            onPressed: () => _showAddPlaceOptions(),
            backgroundColor: Theme.of(context).cardColor,
            elevation: 4,
            child: Icon(
              Icons.add_location_alt,
              color: Theme.of(context).colorScheme.secondary,
              size: 30,
            ),
          ),
        ),
        // Main FAB with menu
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () => _showActionMenu(),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 8,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.add_location_alt,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Add Place'),
              subtitle: const Text('Add a new place with images'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddPlace();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Capture Image'),
              subtitle: const Text('Take a photo and save it'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCaptureImage();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddPlaceOptions() {
    // This will show the same options as the main FAB
    _showActionMenu();
  }

  void _navigateToAddPlace() {
    // Get current location or use default
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlaceScreen(
          currentLocation: const LatLng(0.0, 0.0), // You might want to get actual location
        ),
      ),
    );
  }

  void _navigateToCaptureImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaptureImageScreen(),
      ),
    );
  }
}
