import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../src/core/theme.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/schedule_provider.dart';
import '../../../src/models/schedule_model.dart';
import '../../../src/services/firebase_service.dart';
import 'progress_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(todaysScheduleProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        userAsync.when(
                          data: (user) => Text(
                            user?.displayName ?? 'Student',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/settings'),
                          icon: const Icon(Icons.settings, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => _showLogoutDialog(context, ref),
                          icon: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Quick Access Menu
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickAccessCard(
                                  context,
                                  icon: Icons.subject,
                                  label: 'Subjects',
                                  color: Colors.blue,
                                  onTap: () => Navigator.pushNamed(context, '/subjects'),
                                ),
                                _buildQuickAccessCard(
                                  context,
                                  icon: Icons.note,
                                  label: 'Notes',
                                  color: Colors.purple,
                                  onTap: () => Navigator.pushNamed(context, '/notes'),
                                ),
                                _buildQuickAccessCard(
                                  context,
                                  icon: Icons.analytics,
                                  label: 'Progress',
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(context, '/progress'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: scheduleAsync.when(
                          data: (schedule) {
                            if (schedule == null) {
                              return _buildNoScheduleView(context, ref);
                            }
                            return _buildScheduleView(context, ref, schedule);
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading schedule',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoScheduleView(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Schedule Today',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first study schedule to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              print('Button pressed!');
              _createSampleSchedule(context, ref);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Sample Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(BuildContext context, WidgetRef ref, ScheduleModel schedule) {
    final progress = ref.read(scheduleControllerProvider).getStudyProgress(schedule);
    final remainingMinutes = ref.read(scheduleControllerProvider).getRemainingMinutes(schedule);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Section
          ProgressWidget(
            progress: progress,
            completedMinutes: schedule.completedMinutes,
            totalMinutes: schedule.totalMinutes,
            remainingMinutes: remainingMinutes,
          ),
          const SizedBox(height: 16),
          
          // Adjust Schedule Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/adjust-schedule'),
              icon: const Icon(Icons.schedule),
              label: const Text('Adjust Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Tasks Section
          Text(
            'Today\'s Tasks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Tasks List
          ...schedule.tasks.map((task) => _buildTaskCard(context, ref, task)),
          
          if (schedule.tasks.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All tasks completed!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, ScheduleTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) => _toggleTask(context, ref, task, value ?? false),
          activeColor: AppTheme.primaryGreen,
        ),
        title: Text(
          task.topicName,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : AppTheme.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.subjectName),
            Text(
              '${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')} - ${task.endTime.hour.toString().padLeft(2, '0')}:${task.endTime.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${task.durationMinutes}m',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(BuildContext context, WidgetRef ref, ScheduleTask task, bool isCompleted) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        print('Toggling task: ${task.topicName} to $isCompleted');
        await FirebaseService.updateScheduleTask(
          firebaseUser.uid,
          DateTime.now(),
          task.topicId,
          isCompleted,
        );
        print('Task updated successfully!');
      } else {
        print('No user found');
      }
    } catch (e) {
      print('Error updating task: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSampleSchedule(BuildContext context, WidgetRef ref) async {
    try {
      print('Creating sample schedule...');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('Firebase User: ${firebaseUser?.uid}');
      if (firebaseUser == null) {
        print('Firebase User is null!');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Create sample schedule with mock data
      final sampleSchedule = ScheduleModel(
        id: _formatDateKey(DateTime.now()),
        userId: firebaseUser.uid,
        date: DateTime.now(),
        tasks: [
          ScheduleTask(
            topicId: 'sample-1',
            topicName: 'Mathematics - Calculus',
            subjectId: 'math',
            subjectName: 'Mathematics',
            durationMinutes: 45,
            startTime: DateTime.now().copyWith(hour: 9, minute: 0),
            endTime: DateTime.now().copyWith(hour: 9, minute: 45),
            isCompleted: false,
          ),
          ScheduleTask(
            topicId: 'sample-2',
            topicName: 'Physics - Mechanics',
            subjectId: 'physics',
            subjectName: 'Physics',
            durationMinutes: 60,
            startTime: DateTime.now().copyWith(hour: 10, minute: 0),
            endTime: DateTime.now().copyWith(hour: 11, minute: 0),
            isCompleted: false,
          ),
          ScheduleTask(
            topicId: 'sample-3',
            topicName: 'Chemistry - Organic',
            subjectId: 'chemistry',
            subjectName: 'Chemistry',
            durationMinutes: 30,
            startTime: DateTime.now().copyWith(hour: 11, minute: 15),
            endTime: DateTime.now().copyWith(hour: 11, minute: 45),
            isCompleted: false,
          ),
        ],
        totalMinutes: 135,
        completedMinutes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Write directly to Firestore
      print('Writing schedule to Firestore...');
      await FirebaseService.writeSchedule(firebaseUser.uid, sampleSchedule);
      print('Schedule written successfully!');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample schedule created successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating sample schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}