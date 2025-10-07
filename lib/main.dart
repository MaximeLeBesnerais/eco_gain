import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/stats_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/theme_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _themeColor = 'green';
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final doneOnboarding = prefs.getBool('done_onboarding') ?? false;
    
    final mode = await ThemeHelper.getThemeMode();
    final color = await ThemeHelper.getThemeColor();
    
    setState(() {
      _showOnboarding = !doneOnboarding;
      _themeMode = mode;
      _themeColor = color;
      _isLoading = false;
    });
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
    // Reload theme settings after onboarding
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final mode = await ThemeHelper.getThemeMode();
    final color = await ThemeHelper.getThemeColor();
    setState(() {
      _themeMode = mode;
      _themeColor = color;
    });
  }

  void updateTheme() {
    _loadThemeSettings();
  }

  void _updateThemeImmediately(String color, String mode) {
    setState(() {
      _themeColor = color;
      switch (mode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Gain',
      theme: ThemeHelper.getLightTheme(_themeColor),
      darkTheme: ThemeHelper.getDarkTheme(_themeColor),
      themeMode: _themeMode,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _showOnboarding
              ? OnboardingScreen(
                  onComplete: _completeOnboarding,
                  onThemeChange: _updateThemeImmediately,
                )
              : HomePage(onThemeChanged: updateTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  
  const HomePage({super.key, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Start with Main screen (center)

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const StatsScreen(key: ValueKey('stats'));
      case 1:
        return const MainScreen(key: ValueKey('main'));
      case 2:
        return SettingsScreen(key: const ValueKey('settings'), onThemeChanged: widget.onThemeChanged);
      default:
        return const MainScreen(key: ValueKey('main'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Main',
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
