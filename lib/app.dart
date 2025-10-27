import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/core/theme.dart';
import 'src/providers/settings_provider.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/dashboard/dashboard_screen.dart';
import 'src/features/subject/subject_list_screen.dart';
import 'src/features/subject/add_subject_screen.dart';
import 'src/features/notes/notes_list_screen.dart';
import 'src/features/notes/add_note_screen.dart';
import 'src/features/progress/progress_screen.dart';
import 'src/features/progress/weekly_review_screen.dart';
import 'src/features/settings/settings_screen.dart';
import 'src/features/schedule/adjust_schedule_screen.dart';

class ReviseRightApp extends ConsumerWidget {
  const ReviseRightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'ReviseRight',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: AppLoadingWidget(),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/subjects': (context) => const SubjectListScreen(),
        '/add-subject': (context) => const AddSubjectScreen(),
        '/notes': (context) => const NotesListScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/adjust-schedule': (context) => const AdjustScheduleScreen(),
        '/weekly-review': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return WeeklyReviewScreen(
            weekStartDate: args?['weekStartDate'] ?? DateTime.now(),
          );
        },
      },
    );
  }
}
