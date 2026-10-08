// health_screen.dart - Health overview for all sheep
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sheep_provider.dart';
import '../models/health_model.dart';
import '../utils/app_theme.dart';
import '../widgets/section_header.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            title: const Text('Health Records',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'Upcoming Tasks'),
                Tab(text: 'Health Summary'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _UpcomingTasksTab(),
            _HealthSummaryTab(),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTasksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getUpcomingHealthTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 56, color: AppTheme.accentGreen),
                ),
                const SizedBox(height: 16),
                const Text('All clear!',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('No health tasks due in the next 30 days',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, i) {
            final task = tasks[i];
            final daysUntil = task.nextDueDate
                    ?.difference(DateTime.now())
                    .inDays ??
                0;
            final isOverdue = daysUntil < 0;
            final isUrgent = daysUntil <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOverdue
                      ? AppTheme.accentRed.withOpacity(0.5)
                      : isUrgent
                          ? AppTheme.accent.withOpacity(0.5)
                          : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.accentRed.withOpacity(0.15)
                          : isUrgent
                              ? AppTheme.accent.withOpacity(0.15)
                              : AppTheme.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isOverdue ? '!' : daysUntil.toString(),
                          style: TextStyle(
                            color: isOverdue
                                ? AppTheme.accentRed
                                : isUrgent
                                    ? AppTheme.accent
                                    : AppTheme.accentBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isOverdue ? 'OVERDUE' : 'days',
                          style: TextStyle(
                            color: isOverdue ? AppTheme.accentRed : AppTheme.textMuted,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.description,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(task.type,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                        if (task.nextDueDate != null)
                          Text(
                            DateFormat('d MMMM yyyy').format(task.nextDueDate!),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HealthSummaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sheep = context.watch<SheepProvider>().allSheep;
    final stats = [
      _HealthStat('Total Sheep', sheep.length, AppTheme.accent, Icons.pets_rounded),
      _HealthStat('Active', sheep.where((s) => s.status == 'Active').length, AppTheme.accentGreen, Icons.check_circle_rounded),
      _HealthStat('Quarantine', sheep.where((s) => s.status == 'Quarantine').length, AppTheme.accent, Icons.warning_rounded),
      _HealthStat('Deceased', sheep.where((s) => s.status == 'Deceased').length, AppTheme.accentRed, Icons.cancel_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Flock Health Status', icon: Icons.health_and_safety_rounded),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: stats.length,
            itemBuilder: (context, i) {
              final stat = stats[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: stat.color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(stat.icon, color: stat.color, size: 28),
                    const SizedBox(height: 8),
                    Text(stat.count.toString(),
                        style: TextStyle(
                            color: stat.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 24)),
                    Text(stat.label,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Quick Tips', icon: Icons.lightbulb_rounded),
          const SizedBox(height: 12),
          ..._healthTips.map((tip) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(tip['emoji']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['title']!,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(tip['desc']!,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _HealthStat {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  _HealthStat(this.label, this.count, this.color, this.icon);
}

const _healthTips = [
  {
    'emoji': '💉',
    'title': 'Vaccination Schedule',
    'desc': 'Vaccinate lambs at 4-6 weeks, adults annually.',
  },
  {
    'emoji': '🐛',
    'title': 'Deworming Program',
    'desc': 'Deworm every 4-6 weeks or based on fecal egg count.',
  },
  {
    'emoji': '⚖️',
    'title': 'Regular Weigh-ins',
    'desc': 'Weigh monthly to track growth and health trends.',
  },
  {
    'emoji': '🌾',
    'title': 'Nutrition First',
    'desc': 'Balanced diet prevents most common health issues.',
  },
];
