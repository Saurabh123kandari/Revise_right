import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../src/core/theme.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/settings_provider.dart';
import '../../../src/services/gemini_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final preferences = ref.watch(userPreferencesProvider);
    
    return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Container(
            decoration: AppTheme.gradientBackground,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: AppTheme.getScaffoldBackgroundColor(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Profile Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            userAsync.when(
                              data: (user) => Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text('Display Name'),
                                    subtitle: Text(user?.displayName ?? 'Not set'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      _showEditNameDialog(context, user?.displayName ?? '');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.email),
                                    title: const Text('Email'),
                                    subtitle: Text(user?.email ?? ''),
                                    trailing: const Icon(Icons.lock),
                                  ),
                                ],
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Text('Error loading profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Preferences Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferences',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Theme Mode
                            ListTile(
                              leading: const Icon(Icons.palette),
                              title: const Text('Theme'),
                              subtitle: Text(_getThemeModeText(preferences.themeMode)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showThemeDialog(context, ref),
                            ),
                            
                            const Divider(),
                            
                            // Notifications
                            SwitchListTile(
                              secondary: const Icon(Icons.notifications),
                              title: const Text('Notifications'),
                              subtitle: const Text('Study reminders and updates'),
                              value: preferences.enableNotifications,
                              onChanged: (value) {
                                ref.read(settingsControllerProvider.notifier)
                                    .updatePreference(enableNotifications: value);
                              },
                            ),
                            
                            const Divider(),
                            
                            // Study Reminders
                            SwitchListTile(
                              secondary: const Icon(Icons.school),
                              title: const Text('Study Reminders'),
                              subtitle: const Text('Daily study notifications'),
                              value: preferences.enableStudyReminders,
                              onChanged: (value) {
                                ref.read(settingsControllerProvider.notifier)
                                    .updatePreference(enableStudyReminders: value);
                              },
                            ),
                            
                            const Divider(),
                            
                            // Break Interval
                            ListTile(
                              leading: const Icon(Icons.timer),
                              title: const Text('Break Interval'),
                              subtitle: Text('${preferences.breakIntervalMinutes} minutes'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showBreakIntervalDialog(context, ref, preferences.breakIntervalMinutes),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // AI Integration Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Integration',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.vpn_key),
                              title: const Text('Gemini API Key'),
                              subtitle: const Text('Required for AI quiz generation'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showApiKeyDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // About Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const ListTile(
                              leading: Icon(Icons.info),
                              title: Text('App Version'),
                              subtitle: Text('1.0.0'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.feedback),
                              title: const Text('Feedback'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Open feedback
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showLogoutDialog(context, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.light_mode),
              onTap: () {
                ref.read(settingsControllerProvider.notifier)
                    .updatePreference(themeMode: ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.dark_mode),
              onTap: () {
                ref.read(settingsControllerProvider.notifier)
                    .updatePreference(themeMode: ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () {
                ref.read(settingsControllerProvider.notifier)
                    .updatePreference(themeMode: ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakIntervalDialog(BuildContext context, WidgetRef ref, int currentValue) {
    final controller = TextEditingController(text: currentValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break Interval'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'Enter break interval in minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 25;
              ref.read(settingsControllerProvider.notifier)
                  .updatePreference(breakIntervalMinutes: value);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Update display name in Firestore
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Get your free API key from:\nhttps://ai.google.dev/\n\nFree tier: 1500 requests/day',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Gemini API key',
                border: OutlineInputBorder(),
              ),
              obscureText: false,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await GeminiService.setApiKey(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API key saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving API key: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

