// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';
import 'add_sheep_screen.dart';
import 'health_screen.dart';
import 'breeding_screen.dart';
import 'finance_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sheep = context.watch<SheepProvider>();
    final finance = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStats(context, sheep, finance),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildUpcomingReminders(context, sheep),
                const SizedBox(height: 24),
                _buildFinancialSummary(finance),
                const SizedBox(height: 24),
                _buildTypeChart(sheep),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
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
              padding: const EdgeInsets.fromLTRB(20, 16, 60, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_greeting()}! 👋',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const Text(
                    'Farm Manager',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, SheepProvider sheep, FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Farm Overview', icon: Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: StatCard(
              title: 'Total Animals',
              value: sheep.activeCount.toString(),
              icon: Icons.pets_rounded,
              color: AppTheme.accent,
              subtitle: '${sheep.totalCount} total',
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Females',
              value: sheep.femaleCount.toString(),
              icon: Icons.female_rounded,
              color: const Color(0xFFEC407A),
              subtitle: 'Active females',
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: StatCard(
              title: 'Males',
              value: sheep.maleCount.toString(),
              icon: Icons.male_rounded,
              color: AppTheme.accentBlue,
              subtitle: 'Active males',
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
        ]),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QA('Add Animal', Icons.add_circle_rounded, AppTheme.accent, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSheepScreen()))),
      _QA('Health Log', Icons.medical_services_rounded, const Color(0xFF66BB6A), () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen()))),
      _QA('Breeding', Icons.favorite_rounded, const Color(0xFFEC407A), () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BreedingScreen()))),
      _QA('Finance', Icons.receipt_long_rounded, AppTheme.accentBlue, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()))),
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
          itemBuilder: (ctx, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: a.onTap,
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
                          color: a.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(a.label,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().scale(begin: const Offset(0.8, 0.8)),
            );
          },
        ),
      ],
    );
  }

  // ── Upcoming Reminders ────────────────────────────────────────────
  Widget _buildUpcomingReminders(BuildContext context, SheepProvider sheep) {
    return FutureBuilder(
      future: sheep.getUpcomingHealthTasks(),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
                title: 'Upcoming Health Tasks',
                icon: Icons.notification_important_rounded),
            const SizedBox(height: 12),
            ...tasks.take(3).map((task) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.vaccines_rounded,
                          color: AppTheme.accentRed, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.description,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          if (task.nextDueDate != null)
                            Text(
                                'Due: ${DateFormat('d MMM yyyy').format(task.nextDueDate!)}',
                                style: const TextStyle(
                                    color: AppTheme.accentRed, fontSize: 11)),
                        ],
                      ),
                    ),
                  ]),
                )),
          ],
        );
      },
    );
  }

  // ── Financial Summary ─────────────────────────────────────────────
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
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FinStat('Income',
                    'Rs ${finance.totalIncome.toStringAsFixed(0)}',
                    AppTheme.accentGreen,
                    Icons.arrow_upward_rounded),
                Container(width: 1, height: 50, color: AppTheme.cardBorder),
                _FinStat('Expenses',
                    'Rs ${finance.totalExpense.toStringAsFixed(0)}',
                    AppTheme.accentRed,
                    Icons.arrow_downward_rounded),
                Container(width: 1, height: 50, color: AppTheme.cardBorder),
                _FinStat('Net',
                    'Rs ${finance.netProfit.toStringAsFixed(0)}',
                    finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                    Icons.account_balance_wallet_rounded),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 120, child: _buildBarChart(finance)),
          ]),
        ),
      ],
    );
  }

  Widget _buildBarChart(FinanceProvider finance) {
    final monthly = finance.getMonthlyData(months: 5);
    if (monthly.isEmpty) return const SizedBox.shrink();

    double maxY = 1000;
    for (final m in monthly) {
      final inc = m['income'] as double;
      final exp = m['expense'] as double;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY *= 1.2;

    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, _) {
              final i = val.toInt();
              if (i >= monthly.length) return const SizedBox();
              final parts = (monthly[i]['month'] as String).split('-');
              return Text(months[int.parse(parts[1]) - 1],
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(monthly.length, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: monthly[i]['income'] as double,
              color: AppTheme.accentGreen.withOpacity(0.8),
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          BarChartRodData(
              toY: monthly[i]['expense'] as double,
              color: AppTheme.accentRed.withOpacity(0.8),
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ],
      )),
    ));
  }

  // ── Animal type distribution chart ───────────────────────────────
  Widget _buildTypeChart(SheepProvider sheep) {
    final dist = sheep.getTypeDistribution();
    if (dist.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.accent, AppTheme.accentGreen, AppTheme.accentBlue,
      const Color(0xFFEC407A), const Color(0xFFAB47BC), const Color(0xFFFF7043),
    ];
    final entries = dist.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Animal Distribution', icon: Icons.pie_chart_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(PieChartData(
                sections: List.generate(entries.length, (i) => PieChartSectionData(
                  value: entries[i].value.toDouble(),
                  color: colors[i % colors.length],
                  radius: 55,
                  title: '${entries[i].value}',
                  titleStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                )),
                sectionsSpace: 2,
                centerSpaceRadius: 20,
              )),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(entries.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entries[i].key,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${entries[i].value}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                )),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QA(this.label, this.icon, this.color, this.onTap);
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _FinStat(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]);
}
