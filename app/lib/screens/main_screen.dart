import 'package:app/screens/bobby_chat_screen.dart';
import 'package:app/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'daily_prompt_screen.dart';
import 'time_line_screen.dart';
import 'map_screen.dart';
import '../utils/database_helper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? _userRole;
  LatLng? _currentLocation;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _getCurrentLocation();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // And this line
    super.dispose();
  }

  void _loadUserRole() async {
    final dbHelper = DatabaseHelper();
    final role = await dbHelper.getCharacterChoice();
    if (mounted && role != null) {
      setState(() {
        _userRole = role;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Navigate to location settings if disabled
      await Geolocator.openLocationSettings();
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

    // Get the current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Widget _getBodyWidget(int index) {
    if (_userRole == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (index) {
      case 0:
        return const DailyPromptScreen();
      case 1:
        return TimeLineScreen();
      case 2:
        return MapScreen(currentLocation: _currentLocation);
      case 3:
        return BobbyChatScreen(userRole: _userRole!);
      case 4:
        return QuizScreen();
      default:
        return const Center(child: Text('Screen Not Found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      
      extendBody: true,
      body: Center(child: _getBodyWidget(_selectedIndex)),
      bottomNavigationBar: CurvedNavigationBar(
        height: 60.0,
        index: _selectedIndex,
        items: <Widget>[
          Image.asset(
            _userRole == 'Panda'
                ? 'assets/images/panda_avatar.png'
                : 'assets/images/penguin_avatar.png',
            width: 32,
            height: 32,
            color: _selectedIndex == 0
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.favorite,
            size: 32,
            color: _selectedIndex == 1
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.landscape,
            size: 32,
            color: _selectedIndex == 2
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          Image.asset(
            'assets/images/bobby_avatar.png',
            width: 32,
            height: 32,
            color: _selectedIndex == 3
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.quiz_outlined,
            size: 32,
            color: _selectedIndex == 4
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
