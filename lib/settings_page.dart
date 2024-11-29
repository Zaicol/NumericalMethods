import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode; // Add the current theme mode

  const SettingsScreen(
      {super.key,
        required this.onThemeChanged,
        required this.currentThemeMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall, // Updated from headline6 to headlineSmall
            ),
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}