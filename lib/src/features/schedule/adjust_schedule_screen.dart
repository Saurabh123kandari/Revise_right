import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/schedule_model.dart';
import '../../../src/models/topic_model.dart';
import '../../../src/models/subject_model.dart';
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

  void _showAddTaskDialog() async {
    final subjects = await FirebaseService.getAllSubjects(FirebaseAuth.instance.currentUser!.uid);
    
    if (subjects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a subject first before creating tasks.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    String? selectedSubjectId;
    String? selectedTopicId;
    TimeOfDay selectedTime = TimeOfDay.now();
    int duration = 30;
    int topicRefreshKey = 0; // Key to force FutureBuilder refresh
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Task'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Subject Selection
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedSubjectId,
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    selectedSubjectId = value;
                    selectedTopicId = null; // Reset topic selection
                    setState(() {});
                    
                    // Load topics for selected subject
                    if (selectedSubjectId != null) {
                      final topics = await FirebaseService.getTopicsBySubject(
                        FirebaseAuth.instance.currentUser!.uid,
                        selectedSubjectId!,
                      );
                      // Update UI to show topics
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Topic Selection
                if (selectedSubjectId != null)
                  FutureBuilder<List<TopicModel>>(
                    key: ValueKey(topicRefreshKey),
                    future: FirebaseService.getTopicsBySubject(
                      FirebaseAuth.instance.currentUser!.uid,
                      selectedSubjectId!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final topics = snapshot.data ?? [];
                      if (topics.isEmpty) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No topics available for this subject.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateTopicDialog(context, selectedSubjectId!, setState, () {
                                setState(() {
                                  topicRefreshKey++; // Increment to trigger FutureBuilder refresh
                                });
                              }),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Topic'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedTopicId,
                        items: topics.map((topic) {
                          return DropdownMenuItem(
                            value: topic.id,
                            child: Text(topic.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedTopicId = value;
                          setState(() {});
                        },
                      );
                    },
                  ),
                
                const SizedBox(height: 16),
                
                // Time Selection
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Duration Selection
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  value: duration,
                  items: [15, 30, 45, 60, 90, 120].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minutes'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        duration = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedSubjectId != null && selectedTopicId != null)
                  ? () => _addTask(
                        context,
                        selectedSubjectId!,
                        selectedTopicId!,
                        selectedTime,
                        duration,
                      )
                  : null,
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreateTopicDialog(BuildContext context, String subjectId, StateSetter setState, VoidCallback onTopicCreated) async {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Topic'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Topic Name',
            hintText: 'Enter topic name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final topicName = nameController.text.trim();
              if (topicName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a topic name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              try {
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) return;
                
                // Get subject to get name
                final subject = await FirebaseService.getSubject(firebaseUser.uid, subjectId);
                
                if (subject == null) {
                  throw Exception('Subject not found');
                }
                
                // Create topic with proper data structure
                final now = DateTime.now();
                final topicData = {
                  'id': const Uuid().v4(),
                  'name': topicName,
                  'subjectId': subjectId,
                  'description': '',
                  'priority': 2, // Medium priority default
                  'estimatedMinutes': 30, // Default 30 minutes
                  'createdAt': Timestamp.fromDate(now),
                  'updatedAt': Timestamp.fromDate(now),
                  'isCompleted': false,
                };
                
                await FirebaseService.saveTopic(firebaseUser.uid, topicData);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close topic creation dialog
                  onTopicCreated(); // Trigger FutureBuilder refresh
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating topic: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(
    BuildContext context,
    String subjectId,
    String topicId,
    TimeOfDay time,
    int duration,
  ) async {
    try {
      // Get subject and topic details
      final subject = await FirebaseService.getSubject(
        FirebaseAuth.instance.currentUser!.uid,
        subjectId,
      );
      final topic = await FirebaseService.getTopic(
        FirebaseAuth.instance.currentUser!.uid,
        topicId,
      );
      
      if (subject == null || topic == null) {
        throw Exception('Subject or topic not found');
      }
      
      // Create task
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        time.hour,
        time.minute,
      );
      
      final endTime = startTime.add(Duration(minutes: duration));
      
      final task = ScheduleTask(
        topicId: topicId,
        topicName: topic.name,
        subjectId: subjectId,
        subjectName: subject.name,
        durationMinutes: duration,
        startTime: startTime,
        endTime: endTime,
        isCompleted: false,
      );
      
      // Add task to schedule
      final scheduleController = ref.read(scheduleControllerProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      await scheduleController.addTaskToSchedule(
        userId: firebaseUser.uid,
        date: _selectedDate,
        task: task,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${topic.name}" added successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
