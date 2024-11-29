import 'package:flutter/material.dart';
import 'lab1_page.dart';
import 'lab2_page.dart';
import 'lab2_cpp_page.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'output_page.dart';

void main() {
  runApp(const NumApp());
}

class NumApp extends StatefulWidget {
  const NumApp({super.key});

  @override
  State<NumApp> createState() => _NumAppState();
}

class _NumAppState extends State<NumApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('themeMode');

    // Provide a fallback to ThemeMode.system if themeIndex is null
    setState(() {
      _themeMode = themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system; // Use system as the default fallback
    });
  }

  void _toggleTheme(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = themeMode;
    });
    await prefs.setInt('themeMode', themeMode.index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Метод Якоби',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,
        ),
      ), // Dark theme
      themeMode: _themeMode, // Light, Dark, or System theme
      home: MainScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode; // Add current theme mode

  const MainScreen(
      {super.key, required this.onThemeChanged, required this.currentThemeMode});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<OutputPageState> _outPageKey = GlobalKey<OutputPageState>();

  @override
  void initState() {
    super.initState();
    // Initialize _pages inside initState, where 'widget' can be accessed
    _pages = [
      JacobiScreen(),
      FiniteElementScreen(outputPageKey: _outPageKey,),
      FiniteElementCPPScreen(outputPageKey: _outPageKey,),
      OutputPage(key: _outPageKey),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            label: 'Lab 2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code),
            label: 'Lab 2 CPP',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.output),
            label: 'Output'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
