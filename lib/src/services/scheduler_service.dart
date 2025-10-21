
class SchedulerService {
  /// Generates an optimal study schedule using a greedy algorithm
  /// that considers topic difficulty, due dates, and revision needs
  static List<ScheduleEntry> generateSchedule({
    required List<Topic> topics,
    required DateTime start,
    required Map<DateTime, int> availablePerDay,
  }) {
    // Create a copy of topics to avoid modifying the original list
    final availableTopics = List<Topic>.from(topics);
    final schedule = <ScheduleEntry>[];
    
    // Sort topics by priority score (higher score = higher priority)
    availableTopics.sort((a, b) => _calculatePriorityScore(b).compareTo(_calculatePriorityScore(a)));
    
    // Process each day in chronological order
    final sortedDays = availablePerDay.keys.toList()..sort();
    
    for (final day in sortedDays) {
      final availableMinutes = availablePerDay[day]!;
      int remainingMinutes = availableMinutes;
      
      // Try to schedule topics for this day
      final topicsToRemove = <Topic>[];
      
      for (final topic in availableTopics) {
        if (remainingMinutes <= 0) break;
        
        // Calculate required study time for this topic
        final requiredMinutes = _calculateStudyTime(topic, day);
        
        if (requiredMinutes <= remainingMinutes) {
          // Schedule this topic
          final startTime = _calculateStartTime(day, schedule.length);
          final endTime = startTime.add(Duration(minutes: requiredMinutes));
          
          schedule.add(ScheduleEntry(
            topic: topic,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: requiredMinutes,
            day: day,
          ));
          
          remainingMinutes -= requiredMinutes;
          topicsToRemove.add(topic);
        }
      }
      
      // Remove scheduled topics from available list
      for (final topic in topicsToRemove) {
        availableTopics.remove(topic);
      }
    }
    
    return schedule;
  }
  
  /// Calculates priority score for a topic based on difficulty, due date, and revision needs
  static double _calculatePriorityScore(Topic topic) {
    final now = DateTime.now();
    final daysUntilDue = topic.dueDate.difference(now).inDays;
    
    // Base score from difficulty (higher difficulty = higher priority)
    double score = topic.difficulty * 10;
    
    // Urgency factor based on due date
    if (daysUntilDue <= 0) {
      score += 100; // Overdue - highest priority
    } else if (daysUntilDue <= 1) {
      score += 80; // Due tomorrow
    } else if (daysUntilDue <= 3) {
      score += 60; // Due in 3 days
    } else if (daysUntilDue <= 7) {
      score += 40; // Due in a week
    } else {
      score += 20; // Due later
    }
    
    // Revision factor
    if (topic.revisionNeeded) {
      score += 30; // Boost priority for topics needing revision
    }
    
    // Spacing factor - prefer topics that haven't been studied recently
    final daysSinceLastStudy = now.difference(topic.lastStudied).inDays;
    if (daysSinceLastStudy > 7) {
      score += 25; // Haven't studied in a week
    } else if (daysSinceLastStudy > 3) {
      score += 15; // Haven't studied in 3 days
    }
    
    return score;
  }
  
  /// Calculates required study time for a topic on a specific day
  static int _calculateStudyTime(Topic topic, DateTime day) {
    final daysUntilDue = topic.dueDate.difference(day).inDays;
    
    // Base study time from topic difficulty
    int baseTime = (topic.difficulty * 30).round(); // 30 minutes per difficulty level
    
    // Adjust based on urgency
    if (daysUntilDue <= 0) {
      baseTime = (baseTime * 1.5).round(); // 50% more time for overdue topics
    } else if (daysUntilDue <= 1) {
      baseTime = (baseTime * 1.3).round(); // 30% more time for urgent topics
    }
    
    // Adjust for revision needs
    if (topic.revisionNeeded) {
      baseTime = (baseTime * 1.2).round(); // 20% more time for revision
    }
    
    // Ensure minimum and maximum bounds
    return baseTime.clamp(15, 120); // 15 minutes to 2 hours
  }
  
  /// Calculates start time for a new study session
  static DateTime _calculateStartTime(DateTime day, int sessionIndex) {
    // Start at 9 AM for the first session, then add breaks
    final baseTime = DateTime(day.year, day.month, day.day, 9, 0);
    final breakMinutes = sessionIndex * 15; // 15-minute break between sessions
    return baseTime.add(Duration(minutes: breakMinutes));
  }
  
  /// Optimizes existing schedule by redistributing topics
  static List<ScheduleEntry> optimizeSchedule({
    required List<ScheduleEntry> currentSchedule,
    required List<Topic> availableTopics,
    required Map<DateTime, int> availablePerDay,
  }) {
    // Remove completed topics and reschedule remaining ones
    final incompleteTopics = availableTopics.where((topic) => !topic.isCompleted).toList();
    
    return generateSchedule(
      topics: incompleteTopics,
      start: DateTime.now(),
      availablePerDay: availablePerDay,
    );
  }
  
  /// Calculates schedule efficiency metrics
  static ScheduleMetrics calculateMetrics(List<ScheduleEntry> schedule) {
    if (schedule.isEmpty) {
      return ScheduleMetrics(
        totalStudyTime: 0,
        averageSessionLength: 0,
        topicsCovered: 0,
        efficiencyScore: 0,
      );
    }
    
    final totalStudyTime = schedule.fold(0, (sum, entry) => sum + entry.durationMinutes);
    final averageSessionLength = totalStudyTime / schedule.length;
    final topicsCovered = schedule.map((e) => e.topic.id).toSet().length;
    
    // Calculate efficiency score (0-100)
    final difficultySum = schedule.fold(0.0, (sum, entry) => sum + entry.topic.difficulty);
    final averageDifficulty = difficultySum / schedule.length;
    final efficiencyScore = (averageDifficulty * 20).clamp(0.0, 100.0);
    
    return ScheduleMetrics(
      totalStudyTime: totalStudyTime,
      averageSessionLength: averageSessionLength,
      topicsCovered: topicsCovered,
      efficiencyScore: efficiencyScore,
    );
  }
}

/// Represents a scheduled study session
class ScheduleEntry {
  final Topic topic;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final DateTime day;
  
  const ScheduleEntry({
    required this.topic,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.day,
  });
  
  @override
  String toString() {
    return 'ScheduleEntry(${topic.name}: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}-${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')})';
  }
}

/// Enhanced Topic model with scheduling properties
class Topic {
  final String id;
  final String name;
  final double difficulty; // 1.0 to 5.0
  final DateTime dueDate;
  final bool revisionNeeded;
  final DateTime lastStudied;
  final bool isCompleted;
  
  const Topic({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.dueDate,
    required this.revisionNeeded,
    required this.lastStudied,
    required this.isCompleted,
  });
}

/// Schedule performance metrics
class ScheduleMetrics {
  final int totalStudyTime;
  final double averageSessionLength;
  final int topicsCovered;
  final double efficiencyScore;
  
  const ScheduleMetrics({
    required this.totalStudyTime,
    required this.averageSessionLength,
    required this.topicsCovered,
    required this.efficiencyScore,
  });
}

/*
UNIT TEST STYLE EXAMPLE USAGE:

void main() {
  // Example 1: Basic scheduling
  test('should generate schedule for multiple topics', () {
    final topics = [
      Topic(
        id: '1',
        name: 'Calculus Integration',
        difficulty: 4.0,
        dueDate: DateTime.now().add(Duration(days: 2)),
        revisionNeeded: true,
        lastStudied: DateTime.now().subtract(Duration(days: 3)),
        isCompleted: false,
      ),
      Topic(
        id: '2',
        name: 'Physics Mechanics',
        difficulty: 3.5,
        dueDate: DateTime.now().add(Duration(days: 5)),
        revisionNeeded: false,
        lastStudied: DateTime.now().subtract(Duration(days: 1)),
        isCompleted: false,
      ),
      Topic(
        id: '3',
        name: 'Chemistry Organic',
        difficulty: 2.0,
        dueDate: DateTime.now().add(Duration(days: 7)),
        revisionNeeded: true,
        lastStudied: DateTime.now().subtract(Duration(days: 10)),
        isCompleted: false,
      ),
    ];
    
    final availablePerDay = {
      DateTime.now(): 120, // 2 hours today
      DateTime.now().add(Duration(days: 1)): 90, // 1.5 hours tomorrow
      DateTime.now().add(Duration(days: 2)): 60, // 1 hour day after
    };
    
    final schedule = SchedulerService.generateSchedule(
      topics: topics,
      start: DateTime.now(),
      availablePerDay: availablePerDay,
    );
    
    expect(schedule.length, greaterThan(0));
    expect(schedule.every((entry) => entry.durationMinutes > 0), isTrue);
    
    // Verify that Calculus (highest priority) is scheduled first
    expect(schedule.first.topic.name, equals('Calculus Integration'));
  });
  
  // Example 2: Priority calculation
  test('should prioritize overdue topics', () {
    final overdueTopic = Topic(
      id: '1',
      name: 'Overdue Math',
      difficulty: 2.0,
      dueDate: DateTime.now().subtract(Duration(days: 1)), // Overdue
      revisionNeeded: false,
      lastStudied: DateTime.now().subtract(Duration(days: 5)),
      isCompleted: false,
    );
    
    final normalTopic = Topic(
      id: '2',
      name: 'Normal Science',
      difficulty: 4.0,
      dueDate: DateTime.now().add(Duration(days: 5)),
      revisionNeeded: false,
      lastStudied: DateTime.now().subtract(Duration(days: 1)),
      isCompleted: false,
    );
    
    final availablePerDay = {DateTime.now(): 60};
    
    final schedule = SchedulerService.generateSchedule(
      topics: [overdueTopic, normalTopic],
      start: DateTime.now(),
      availablePerDay: availablePerDay,
    );
    
    // Overdue topic should be scheduled first despite lower difficulty
    expect(schedule.first.topic.name, equals('Overdue Math'));
  });
  
  // Example 3: Schedule optimization
  test('should optimize existing schedule', () {
    final topics = [
      Topic(
        id: '1',
        name: 'Completed Topic',
        difficulty: 3.0,
        dueDate: DateTime.now().add(Duration(days: 1)),
        revisionNeeded: false,
        lastStudied: DateTime.now(),
        isCompleted: true, // Already completed
      ),
      Topic(
        id: '2',
        name: 'Remaining Topic',
        difficulty: 2.0,
        dueDate: DateTime.now().add(Duration(days: 2)),
        revisionNeeded: false,
        lastStudied: DateTime.now().subtract(Duration(days: 1)),
        isCompleted: false,
      ),
    ];
    
    final availablePerDay = {DateTime.now(): 90};
    
    final optimizedSchedule = SchedulerService.optimizeSchedule(
      currentSchedule: [],
      availableTopics: topics,
      availablePerDay: availablePerDay,
    );
    
    // Should only schedule the incomplete topic
    expect(optimizedSchedule.length, equals(1));
    expect(optimizedSchedule.first.topic.name, equals('Remaining Topic'));
  });
  
  // Example 4: Metrics calculation
  test('should calculate schedule metrics', () {
    final topics = [
      Topic(
        id: '1',
        name: 'Math',
        difficulty: 4.0,
        dueDate: DateTime.now().add(Duration(days: 1)),
        revisionNeeded: false,
        lastStudied: DateTime.now().subtract(Duration(days: 1)),
        isCompleted: false,
      ),
    ];
    
    final availablePerDay = {DateTime.now(): 60};
    
    final schedule = SchedulerService.generateSchedule(
      topics: topics,
      start: DateTime.now(),
      availablePerDay: availablePerDay,
    );
    
    final metrics = SchedulerService.calculateMetrics(schedule);
    
    expect(metrics.totalStudyTime, greaterThan(0));
    expect(metrics.topicsCovered, equals(1));
    expect(metrics.efficiencyScore, greaterThan(0));
  });
}
*/