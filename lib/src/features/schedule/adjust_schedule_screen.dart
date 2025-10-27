import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/schedule_model.dart';
import '../../../src/providers/schedule_provider.dart';
import '../../../src/services/firebase_service.dart';

class AdjustScheduleScreen extends ConsumerStatefulWidget {
  const AdjustScheduleScreen({super.key});

  @override
  ConsumerState<AdjustScheduleScreen> createState() => _AdjustScheduleScreenState();
}

class _AdjustScheduleScreenState extends ConsumerState<AdjustScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isWeeklyView = false;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Schedule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isWeeklyView ? Icons.calendar_today : Icons.view_week),
            onPressed: () {
              setState(() {
                _isWeeklyView = !_isWeeklyView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Date Navigation
              _buildDateNavigation(),
              
              // Calendar View
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.getScaffoldBackgroundColor(context),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: _isWeeklyView ? _buildWeeklyView() : _buildDailyView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getScaffoldBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(
                  _isWeeklyView ? const Duration(days: 7) : const Duration(days: 1),
                );
              });
            },
          ),
          Text(
            _isWeeklyView
                ? 'Week of ${DateFormat('MMM d').format(_getWeekStart())}'
                : DateFormat('EEEE, MMM d, y').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(
                  _isWeeklyView ? const Duration(days: 7) : const Duration(days: 1),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    return Column(
      children: [
        // Time slots header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 60, child: Text('Time')),
              const Expanded(child: Text('Tasks')),
              const SizedBox(width: 80, child: Text('Duration')),
            ],
          ),
        ),
        
        // Schedule content
        Expanded(
          child: _buildScheduleContent(),
        ),
      ],
    );
  }

  Widget _buildWeeklyView() {
    return Column(
      children: [
        // Week header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: List.generate(7, (index) {
              final date = _getWeekStart().add(Duration(days: index));
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, _selectedDate);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : isToday
                              ? AppTheme.primaryGreen.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        
        // Weekly schedule content
        Expanded(
          child: _buildWeeklyScheduleContent(),
        ),
      ],
    );
  }

  Widget _buildScheduleContent() {
    return FutureBuilder<ScheduleModel?>(
      future: _getScheduleForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading schedule',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final schedule = snapshot.data;
        if (schedule == null || schedule.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 64,
                  color: AppTheme.primaryGreen.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks scheduled',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textDark.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a task',
                  style: TextStyle(
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: schedule.tasks.length,
          itemBuilder: (context, index) {
            final task = schedule.tasks[index];
            return _buildTaskItem(task, index);
          },
        );
      },
    );
  }

  Widget _buildWeeklyScheduleContent() {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = _getWeekStart().add(Duration(days: index));
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<ScheduleModel?>(
                future: _getScheduleForDate(date),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 20,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final schedule = snapshot.data;
                  if (schedule == null || schedule.tasks.isEmpty) {
                    return Text(
                      'No tasks',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  
                  return Column(
                    children: schedule.tasks.map((task) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('HH:mm').format(task.startTime),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.topicName,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${task.durationMinutes}m',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(ScheduleTask task, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.white,
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.primaryGreen
              : Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('HH:mm').format(task.startTime),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          
          // Task details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.topicName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  task.subjectName,
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Duration
          SizedBox(
            width: 80,
            child: Text(
              '${task.durationMinutes}m',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) => _handleTaskAction(value, task),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      task.isCompleted ? Icons.undo : Icons.check,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<ScheduleModel?> _getScheduleForDate(DateTime date) async {
    try {
      final scheduleController = ref.read(scheduleControllerProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;
      
      return await FirebaseService.getSchedule(firebaseUser.uid, date);
    } catch (e) {
      print('Error getting schedule for $date: $e');
      return null;
    }
  }

  DateTime _getWeekStart() {
    final now = _selectedDate;
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleTaskAction(String action, ScheduleTask task) {
    switch (action) {
      case 'toggle':
        _toggleTaskCompletion(task);
        break;
      case 'edit':
        _editTask(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
    }
  }

  void _toggleTaskCompletion(ScheduleTask task) async {
    try {
      final scheduleController = ref.read(scheduleControllerProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      await scheduleController.markTaskCompleted(
        userId: firebaseUser.uid,
        date: _selectedDate,
        topicId: task.topicId,
        isCompleted: !task.isCompleted,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.isCompleted
                  ? 'Task marked as incomplete'
                  : 'Task marked as complete',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editTask(ScheduleTask task) {
    // TODO: Implement edit task functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit task functionality coming soon'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _deleteTask(ScheduleTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.topicName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete task functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete task functionality coming soon'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: const Text('Add task functionality will be implemented in the next step.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
