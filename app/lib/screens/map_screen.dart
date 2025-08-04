import 'dart:math';

import 'package:app/screens/add_place_screen.dart';
import 'package:app/screens/capture_image_screen.dart';
import 'package:app/screens/place_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import '../providers/map_provider.dart';
import '../utils/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _userRole;
  LatLng? _currentLocation; // New state variable for user's location

  @override
  void initState() {
    super.initState();
    _loadUserAndLocation();
  }

  void _loadUserAndLocation() async {
    final role = await DatabaseHelper().getCharacterChoice();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
      context.read<MapProvider>().fetchPlaces();
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _viewRandomPlace(MapProvider mapProvider) {
    if (mapProvider.places.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(mapProvider.places.length);
      final randomPlace = mapProvider.places[randomIndex];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaceGalleryScreen(place: randomPlace),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No places added yet!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Our Adventures',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map with a fixed height relative to the screen size
            SizedBox(
              height:
                  screenHeight *
                  0.5, // The map takes up 50% of the screen height
              child: _currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.our_little_world',
                        ),
                        MarkerLayer(
                          markers: mapProvider.places.map((place) {
                            return Marker(
                              width: 60.0,
                              height: 60.0,
                              point: LatLng(place.latitude, place.longitude),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PlaceGalleryScreen(place: place),
                                    ),
                                  );
                                },
                                child: Image.asset(
                                  place.authorRole == 'Panda'
                                      ? 'assets/images/panda_avatar.png'
                                      : 'assets/images/penguin_avatar.png',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            // The buttons below the map
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFloatingIconButton(
                    icon: Icons.add_location_alt,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPlaceScreen(
                            currentLocation:
                                _currentLocation ?? LatLng(0.0, 0.0),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildFloatingIconButton(
                    icon: Icons.camera_alt,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CaptureImageScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFloatingIconButton(
                    icon: Icons.shuffle,
                    onPressed: () {
                      _viewRandomPlace(mapProvider);
                    },
                  ),
                ],
              ),
            ),
            Text(
              "It's Only Us",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/panda_avatar.png',
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(width: 35),
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 40,
                  ),
                  const SizedBox(width: 20),
                  Image.asset(
                    'assets/images/penguin_avatar.png',
                    width: 70,
                    height: 70,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      heroTag: icon.codePoint
          .toString(), // Prevents hero animation tag conflicts
      onPressed: onPressed,
      backgroundColor: Theme.of(context).cardColor,
      elevation: 4,
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.secondary,
        size: 30,
      ),
    );
  }
}
