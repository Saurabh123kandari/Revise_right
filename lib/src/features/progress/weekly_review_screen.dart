import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/schedule_model.dart';
import '../../../src/providers/schedule_provider.dart';
import '../../../src/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  final DateTime weekStartDate;

  const WeeklyReviewScreen({super.key, required this.weekStartDate});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  late DateTime _weekStart;
  late DateTime _weekEnd;
  Map<String, dynamic> _weeklyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _weekStart = widget.weekStartDate;
    _weekEnd = _weekStart.add(const Duration(days: 6));
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final stats = <String, dynamic>{
        'totalMinutes': 0,
        'completedMinutes': 0,
        'totalTasks': 0,
        'completedTasks': 0,
        'dailyBreakdown': <Map<String, dynamic>>[],
        'topics': <String, int>{},
      };

      // Load data for each day of the week
      for (int i = 0; i < 7; i++) {
        final date = _weekStart.add(Duration(days: i));
        final schedule = await FirebaseService.getSchedule(
          firebaseUser.uid,
          date,
        );

        if (schedule != null) {
          stats['totalMinutes'] = (stats['totalMinutes'] as int) +
              schedule.totalMinutes;
          stats['completedMinutes'] = (stats['completedMinutes'] as int) +
              schedule.completedMinutes;
          stats['totalTasks'] = (stats['totalTasks'] as int) +
              schedule.tasks.length;
          stats['completedTasks'] = (stats['completedTasks'] as int) +
              schedule.tasks.where((t) => t.isCompleted).length;

          // Track topics
          for (final task in schedule.tasks) {
            final topic = task.topicName;
            stats['topics'] = stats['topics'] as Map<String, int>;
            stats['topics'][topic] = (stats['topics'][topic] ?? 0) + 1;
          }

          // Daily breakdown
          (stats['dailyBreakdown'] as List).add({
            'date': date,
            'completed': schedule.completedMinutes,
            'total': schedule.totalMinutes,
            'tasks': schedule.tasks.length,
            'completedTasks': schedule.tasks.where((t) => t.isCompleted).length,
          });
        }
      }

      setState(() {
        _weeklyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weekly data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Week of ${DateFormat('MMM d').format(_weekStart)}',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final completionRate = _weeklyStats['totalMinutes'] != null &&
            _weeklyStats['totalMinutes'] > 0
        ? ((_weeklyStats['completedMinutes'] as int) /
                (_weeklyStats['totalMinutes'] as int) *
                100)
            .toStringAsFixed(1)
        : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(completionRate),
          const SizedBox(height: 24),

          // Daily Study Time Chart
          _buildDailyStudyChart(),
          const SizedBox(height: 24),

          // Task Completion Chart
          _buildTaskCompletionChart(),
          const SizedBox(height: 24),

          // Topics Studied
          _buildTopicsSection(),
          const SizedBox(height: 24),

          // Weekly Insights
          _buildInsightsSection(completionRate),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String completionRate) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Time',
            _formatMinutes(_weeklyStats['totalMinutes'] ?? 0),
            Icons.access_time,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completion',
            '$completionRate%',
            Icons.check_circle,
            AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Tasks Done',
            '${_weeklyStats['completedTasks'] ?? 0}/${_weeklyStats['totalTasks'] ?? 0}',
            Icons.task_alt,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStudyChart() {
    final dailyData = _weeklyStats['dailyBreakdown'] as List;
    final maxValue = dailyData.isEmpty
        ? 60
        : dailyData
            .map<int>((d) => d['total'] as int)
            .reduce((a, b) => a > b ? a : b);

    if (dailyData.isEmpty) {
      return _buildEmptyState(
        'No study data available',
        'Start studying to see your weekly progress!',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Study Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue + 30,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final intValue = value.toInt();
                        if (intValue >= 0 && intValue < dailyData.length) {
                          final date = dailyData[intValue]['date'] as DateTime;
                          return Text(
                            DateFormat('E').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Minutes'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(
                  dailyData.length,
                  (index) {
                    final completed = dailyData[index]['completed'] as int;
                    final total = dailyData[index]['total'] as int;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: total.toDouble(),
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: completed.toDouble(),
                          color: AppTheme.primaryGreen,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionChart() {
    final total = _weeklyStats['totalTasks'] ?? 0;
    final completed = _weeklyStats['completedTasks'] ?? 0;
    final remaining = total - completed;

    if (total == 0) {
      return _buildEmptyState(
        'No tasks scheduled',
        'Add tasks to track your progress!',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Completion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: completed.toDouble(),
                    title: 'Completed\n$completed',
                    color: AppTheme.primaryGreen,
                    radius: 80,
                  ),
                  if (remaining > 0)
                    PieChartSectionData(
                      value: remaining.toDouble(),
                      title: 'Remaining\n$remaining',
                      color: Colors.grey.withOpacity(0.3),
                      radius: 80,
                    ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection() {
    final topics = _weeklyStats['topics'] as Map<String, int>;

    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTopics = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topics Studied',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedTopics.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.library_books,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value} times',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(String completionRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryYellow, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Weekly Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            double.parse(completionRate) >= 80
                ? 'Great job! You maintained a high completion rate.'
                : 'You can improve by completing more tasks.',
            double.parse(completionRate) >= 80 ? Icons.trending_up : Icons.trending_down,
            double.parse(completionRate) >= 80 ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Keep up the consistency with your daily study sessions!',
            Icons.calendar_today,
            AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/adjust-schedule'),
            icon: const Icon(Icons.schedule),
            label: const Text('Adjust Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}
