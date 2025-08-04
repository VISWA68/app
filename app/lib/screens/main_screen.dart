import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'daily_prompt_screen.dart';
import 'time_line_screen.dart';
//import 'map_screen.dart'; // Uncomment this once you start building the map screen
import '../utils/database_helper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _userRole = 'Panda';

  final List<Widget> _widgetOptions = <Widget>[
    const DailyPromptScreen(),
    TimeLineScreen(),
    const Text('Map Screen (Coming Soon!)'), // Use a placeholder for now
    // Uncomment the line below once the MapScreen is ready
    // const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // This is important for the curved bar
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: CurvedNavigationBar(
        height: 60.0,
        index: _selectedIndex,
        items: <Widget>[
          // Home/Prompt screen icon
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
          // Memories screen icon
          Icon(
            Icons.favorite, // Using a heart icon for memories
            size: 32,
            color: _selectedIndex == 1
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          // Adventures/Map screen icon
          Icon(
            Icons.landscape, // A cute mountain icon for adventures
            size: 32,
            color: _selectedIndex == 2
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Colors.transparent, // Makes it a floating bar
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
