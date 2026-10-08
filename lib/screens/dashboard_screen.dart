// dashboard_screen.dart - Main dashboard with farm overview
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import '../services/backup_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';
import 'add_sheep_screen.dart';
import 'health_screen.dart';
import 'breeding_screen.dart';
import 'finance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _backupService = BackupService();
  bool _backingUp = false;

  @override
  Widget build(BuildContext context) {
    final sheepProvider = context.watch<SheepProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final stats = sheepProvider.statistics;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Farm stats row
                _buildStatsSection(sheepProvider, financeProvider),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Upcoming reminders
                _buildUpcomingReminders(sheepProvider),
                const SizedBox(height: 24),

                // Financial summary
                _buildFinancialSummary(financeProvider),
                const SizedBox(height: 24),

                // Breed distribution chart
                _buildBreedChart(sheepProvider),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final now = DateTime.now();
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B2A), Color(0xFF1A2E45)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_getGreeting()}! 👋',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'Sheep Farm Manager',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _backingUp
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accent,
                                  ),
                                )
                              : IconButton(
                                  onPressed: _handleBackup,
                                  icon: const Icon(Icons.cloud_upload_rounded,
                                      color: AppTheme.accent),
                                  tooltip: 'Backup to Cloud',
                                ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                            icon: const Icon(Icons.settings_rounded,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(SheepProvider sheep, FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Farm Overview', icon: Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Flock',
                value: sheep.activeCount.toString(),
                icon: Icons.pets_rounded,
                color: AppTheme.accent,
                subtitle: '${sheep.totalCount} total',
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Ewes',
                value: sheep.femaleCount.toString(),
                icon: Icons.female_rounded,
                color: const Color(0xFFEC407A),
                subtitle: 'Female sheep',
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Rams',
                value: sheep.maleCount.toString(),
                icon: Icons.male_rounded,
                color: AppTheme.accentBlue,
                subtitle: 'Male sheep',
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Net Profit',
                value: 'Rs ${finance.netProfit.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                color: finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                subtitle: 'All time',
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Add Sheep', Icons.add_circle_rounded, AppTheme.accent, '/add-sheep'),
      _QuickAction('Health Log', Icons.medical_services_rounded, const Color(0xFF66BB6A), '/health'),
      _QuickAction('Breeding', Icons.favorite_rounded, const Color(0xFFEC407A), '/breeding'),
      _QuickAction('Finance', Icons.receipt_long_rounded, AppTheme.accentBlue, '/finance'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions', icon: Icons.flash_on_rounded),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final action = actions[i];
            return GestureDetector(
              onTap: () => _handleQuickAction(context, action.route),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().scale(begin: const Offset(0.8, 0.8)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingReminders(SheepProvider sheepProvider) {
    return FutureBuilder(
      future: sheepProvider.getUpcomingHealthTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Upcoming Health Tasks',
              icon: Icons.notification_important_rounded,
            ),
            const SizedBox(height: 12),
            ...tasks.take(3).map((task) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.vaccines_rounded,
                            color: AppTheme.accentRed, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.description,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            if (task.nextDueDate != null)
                              Text(
                                'Due: ${DateFormat('d MMM yyyy').format(task.nextDueDate!)}',
                                style: const TextStyle(
                                    color: AppTheme.accentRed, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildFinancialSummary(FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Financial Overview', icon: Icons.account_balance_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FinanceStat(
                      label: 'Income',
                      value: 'Rs ${finance.totalIncome.toStringAsFixed(0)}',
                      color: AppTheme.accentGreen,
                      icon: Icons.arrow_upward_rounded),
                  Container(width: 1, height: 50, color: AppTheme.cardBorder),
                  _FinanceStat(
                      label: 'Expenses',
                      value: 'Rs ${finance.totalExpense.toStringAsFixed(0)}',
                      color: AppTheme.accentRed,
                      icon: Icons.arrow_downward_rounded),
                  Container(width: 1, height: 50, color: AppTheme.cardBorder),
                  _FinanceStat(
                      label: 'Net',
                      value: 'Rs ${finance.netProfit.toStringAsFixed(0)}',
                      color: finance.netProfit >= 0
                          ? AppTheme.accentGreen
                          : AppTheme.accentRed,
                      icon: Icons.account_balance_wallet_rounded),
                ],
              ),
              const SizedBox(height: 16),
              // Monthly trend chart
              SizedBox(
                height: 120,
                child: _buildFinanceBarChart(finance),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceBarChart(FinanceProvider finance) {
    final monthlyData = finance.getMonthlyData(months: 5);
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyData
                .map((m) => [m['income'] as double, m['expense'] as double])
                .expand((e) => e)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyData.length) return const SizedBox();
                final month = monthlyData[value.toInt()]['month'] as String;
                final parts = month.split('-');
                return Text(
                  _getMonthAbbrev(int.parse(parts[1])),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(monthlyData.length, (i) {
          final m = monthlyData[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (m['income'] as double),
                color: AppTheme.accentGreen.withOpacity(0.8),
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: (m['expense'] as double),
                color: AppTheme.accentRed.withOpacity(0.8),
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBreedChart(SheepProvider sheep) {
    final distribution = sheep.getBreedDistribution();
    if (distribution.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.accent,
      AppTheme.accentGreen,
      AppTheme.accentBlue,
      const Color(0xFFEC407A),
      const Color(0xFFAB47BC),
    ];

    final sections = distribution.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Breed Distribution', icon: Icons.pie_chart_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(sections.length, (i) {
                      final entry = sections[i];
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        color: colors[i % colors.length],
                        radius: 55,
                        title: '${entry.value}',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 20,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(sections.length, (i) {
                    final entry = sections[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key.isEmpty ? 'Unknown' : entry.key,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleQuickAction(BuildContext context, String route) {
    Widget? targetScreen;
    if (route == '/add-sheep') {
      targetScreen = const AddSheepScreen();
    } else if (route == '/health') {
      targetScreen = const HealthScreen();
    } else if (route == '/breeding') {
      targetScreen = const BreedingScreen();
    } else if (route == '/finance') {
      targetScreen = const FinanceScreen();
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen!),
      );
    }
  }

  Future<void> _handleBackup() async {
    if (!_backupService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in with Google first (Settings → Backup)'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }
    setState(() => _backingUp = true);
    final result = await _backupService.backupToCloud();
    setState(() => _backingUp = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _getMonthAbbrev(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  _QuickAction(this.label, this.icon, this.color, this.route);
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FinanceStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
