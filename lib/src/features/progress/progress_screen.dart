import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../src/core/theme.dart';
import '../../../src/providers/progress_provider.dart';

final weeklyStatsProvider = FutureProvider((ref) {
  return ref.read(progressControllerProvider).getWeeklyStats();
});

final subjectStatsProvider = FutureProvider((ref) {
  return ref.read(progressControllerProvider).getSubjectStats();
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final subjectStatsAsync = ref.watch(subjectStatsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: weeklyStatsAsync.when(
              data: (weeklyStats) => _buildContent(
                context,
                weeklyStats,
                subjectStatsAsync,
                ref,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to weekly review
          // Navigator.pushNamed(context, '/weekly-review');
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.assessment),
        label: const Text('Weekly Review'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<StudyStat> weeklyStats,
    AsyncValue<List<SubjectStats>> subjectStatsAsync,
    WidgetRef ref,
  ) {
    final controller = ref.read(progressControllerProvider);
    final totalMinutes = controller.getTotalMinutes(weeklyStats);
    final streak = controller.calculateStreak(weeklyStats);
    final avgMinutes = controller.getAverageMinutes(weeklyStats);
    final completionRate = controller.getCompletionRate(weeklyStats);
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.schedule,
                title: 'Total Time',
                value: '$totalMinutes min',
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.local_fire_department,
                title: 'Streak',
                value: '$streak days',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.trending_up,
                title: 'Avg Daily',
                value: '${avgMinutes.toStringAsFixed(0)} min',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.check_circle,
                title: 'Completion',
                value: '${(completionRate * 100).toStringAsFixed(0)}%',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Weekly Study Time Chart
        _buildWeeklyChart(context, weeklyStats),
        const SizedBox(height: 24),
        
        // Subject Distribution
        subjectStatsAsync.when(
          data: (subjectStats) => _buildSubjectPieChart(context, subjectStats),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<StudyStat> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Study Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: stats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.minutesStudied.toDouble(),
                          color: AppTheme.primaryGreen,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _getDayName(value.toInt()),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
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
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPieChart(BuildContext context, List<SubjectStats> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time by Subject',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: stats.map((stat) {
                    final total = stats.fold(0, (sum, s) => sum + s.totalMinutes);
                    final percentage = total > 0 ? stat.totalMinutes / total : 0;
                    
                    return PieChartSectionData(
                      value: stat.totalMinutes.toDouble(),
                      title: '${(percentage * 100).toStringAsFixed(0)}%',
                      color: _getSubjectColor(stat.subjectId),
                      radius: 80,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...stats.map((stat) => _buildLegendItem(
              context,
              stat.subjectName,
              stat.totalMinutes,
              _getSubjectColor(stat.subjectId),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    int minutes,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$minutes min',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subjectId) {
    switch (subjectId) {
      case 'math':
        return Colors.blue;
      case 'physics':
        return Colors.orange;
      case 'chemistry':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (index >= 0 && index < days.length) {
      return days[index];
    }
    return '';
  }
}

