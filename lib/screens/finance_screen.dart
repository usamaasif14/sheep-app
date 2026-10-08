// finance_screen.dart - Complete financial management for sheep farm
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/breeding_model.dart';
import '../models/sheep_model.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _typeFilter = 'All'; // 'All', 'Income', 'Expense'
  String _selectedCategory = 'All';

  List<String> _incomeCategories = [
    'Sheep Sale',
    'Wool & Shearing',
    'Meat Sale',
    'Milk & Dairy',
    'Breeding Fee',
    'Government Subsidy',
    'Other Income',
  ];

  List<String> _expenseCategories = [
    'Feed & Fodder',
    'Veterinary & Medicine',
    'Vaccinations',
    'Shearing Costs',
    'Equipment & Infrastructure',
    'Labor & Staff',
    'Transportation',
    'Other Expense',
  ];

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
    final finance = context.watch<FinanceProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            title: const Text(
              'Farm Finances',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
                onPressed: () => _showManageCategoriesDialog(context),
                tooltip: 'Manage Categories',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accent),
                onPressed: () => _showAddTransactionModal(context),
                tooltip: 'Add Transaction',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Analytics & Reports'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTransactionsTab(finance, currencyFormat),
            _buildAnalyticsTab(finance, currencyFormat),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildTransactionsTab(FinanceProvider finance, NumberFormat currencyFormat) {
    var records = finance.records;
    if (_typeFilter != 'All') {
      records = records.where((r) => r.type == _typeFilter).toList();
    }
    if (_selectedCategory != 'All') {
      records = records.where((r) => r.category == _selectedCategory).toList();
    }

    return RefreshIndicator(
      onRefresh: () => finance.loadRecords(),
      color: AppTheme.accent,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overview cards
                _buildSummaryCards(finance, currencyFormat),
                const SizedBox(height: 20),

                // Filters
                _buildFilterChips(),
                const SizedBox(height: 16),

                SectionHeader(
                  title: 'Transaction History (${records.length})',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 12),
                _buildPurchaseCostSection(),
              ]),
            ),
          ),

          if (finance.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (records.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No financial records found',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap + Add Entry to log farm sales or expenses',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = records[index];
                    return _buildTransactionCard(item, currencyFormat, index);
                  },
                  childCount: records.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FinanceProvider finance, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Income',
                value: currencyFormat.format(finance.totalIncome),
                icon: Icons.arrow_upward_rounded,
                color: AppTheme.accentGreen,
                subtitle: 'Sales & earnings',
              ).animate().fadeIn().slideX(begin: -0.1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Expenses',
                value: currencyFormat.format(finance.totalExpense),
                icon: Icons.arrow_downward_rounded,
                color: AppTheme.accentRed,
                subtitle: 'Feed, vet & costs',
              ).animate().fadeIn().slideX(begin: 0.1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: finance.netProfit >= 0
                  ? AppTheme.accentGreen.withOpacity(0.3)
                  : AppTheme.accentRed.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      finance.netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Profit / Loss',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        currencyFormat.format(finance.netProfit),
                        style: TextStyle(
                          color: finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finance.netProfit >= 0 ? 'Profitable' : 'Deficit',
                  style: TextStyle(
                    color: finance.netProfit >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', _typeFilter == 'All', (val) {
            setState(() {
              _typeFilter = 'All';
              _selectedCategory = 'All';
            });
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Income', _typeFilter == 'Income', (val) {
            setState(() {
              _typeFilter = 'Income';
              _selectedCategory = 'All';
            });
          }, color: AppTheme.accentGreen),
          const SizedBox(width: 8),
          _buildFilterChip('Expense', _typeFilter == 'Expense', (val) {
            setState(() {
              _typeFilter = 'Expense';
              _selectedCategory = 'All';
            });
          }, color: AppTheme.accentRed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected, {Color? color}) {
    final chipColor = color ?? AppTheme.accent;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 12,
      ),
    );
  }

  Widget _buildPurchaseCostSection() {
    return Consumer<SheepProvider>(
      builder: (context, sheep, _) {
        final animals = sheep.allAnimals.where((a) => a.purchaseCost != null && a.purchaseCost! > 0).toList();
        if (animals.isEmpty || _typeFilter == 'Income') return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Animal Purchase Costs', icon: Icons.shopping_cart_rounded),
            const SizedBox(height: 8),
            ...animals.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.accentRed.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.pets_rounded, color: AppTheme.accentRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Animal Purchase', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('- PKR ${a.purchaseCost!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  Text('${a.tagNumber}${a.name.isNotEmpty ? " — ${a.name}" : ""} (${a.animalType})',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(DateFormat('d MMM yyyy').format(a.dateAdded),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ])),
              ]),
            )).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(FinancialRecord item, NumberFormat currencyFormat, int index) {
    final isIncome = item.type == 'Income';
    final color = isIncome ? AppTheme.accentGreen : AppTheme.accentRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'} ${currencyFormat.format(item.amount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy').format(item.date),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 18),
            onPressed: () => _confirmDelete(item.id),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAnalyticsTab(FinanceProvider finance, NumberFormat currencyFormat) {
    final monthlyData = finance.getMonthlyData(months: 6);
    final expenseCategories = finance.getExpenseByCategory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Income vs Expense (6 Months)', icon: Icons.insights_rounded),
          const SizedBox(height: 12),

          // Bar chart
          Container(
            padding: const EdgeInsets.all(16),
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: monthlyData.isEmpty
                ? const Center(child: Text('No monthly data available', style: TextStyle(color: AppTheme.textMuted)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calculateMaxY(monthlyData),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              if (val.toInt() >= monthlyData.length) return const SizedBox();
                              final m = monthlyData[val.toInt()]['month'] as String;
                              final monthNum = int.parse(m.split('-')[1]);
                              const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              return Text(names[monthNum - 1], style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
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
                              color: AppTheme.accentGreen,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: (m['expense'] as double),
                              color: AppTheme.accentRed,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppTheme.accentGreen, 'Income'),
              const SizedBox(width: 20),
              _buildLegend(AppTheme.accentRed, 'Expense'),
            ],
          ),

          const SizedBox(height: 24),
          const SectionHeader(title: 'Expenses by Category', icon: Icons.pie_chart_rounded),
          const SizedBox(height: 12),

          if (expenseCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Center(
                child: Text('No expense data to analyze yet', style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: expenseCategories.entries.map((entry) {
                  final totalExp = finance.totalExpense > 0 ? finance.totalExpense : 1.0;
                  final percentage = (entry.value / totalExp) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('${currencyFormat.format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(color: AppTheme.accentRed, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (percentage / 100).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.primaryLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentRed),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> monthly) {
    double maxVal = 1000;
    for (final m in monthly) {
      final inc = m['income'] as double;
      final exp = m['expense'] as double;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    return maxVal * 1.25;
  }

  void _showAddTransactionModal(BuildContext context) {
    final sheepProvider = context.read<SheepProvider>();
    final sheepList = sheepProvider.allSheep;

    String selectedType = 'Income';
    String selectedCategory = _incomeCategories.first;
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime transactionDate = DateTime.now();
    String? selectedSheepId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final categories = selectedType == 'Income' ? _incomeCategories : _expenseCategories;
          if (!categories.contains(selectedCategory)) {
            selectedCategory = categories.first;
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Transaction',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Income / Expense Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedType = 'Income';
                              selectedCategory = _incomeCategories.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'Income'
                                  ? AppTheme.accentGreen.withOpacity(0.2)
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedType == 'Income' ? AppTheme.accentGreen : AppTheme.cardBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: selectedType == 'Income' ? AppTheme.accentGreen : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedType = 'Expense';
                              selectedCategory = _expenseCategories.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'Expense'
                                  ? AppTheme.accentRed.withOpacity(0.2)
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedType == 'Expense' ? AppTheme.accentRed : AppTheme.cardBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                color: selectedType == 'Expense' ? AppTheme.accentRed : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs)',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: AppTheme.primaryLight,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppTheme.textPrimary))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Description / Purpose',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Linked Sheep (optional)
                  DropdownButtonFormField<String?>(
                    value: selectedSheepId,
                    dropdownColor: AppTheme.primaryLight,
                    decoration: const InputDecoration(
                      labelText: 'Linked Sheep (Optional)',
                      prefixIcon: Icon(Icons.pets_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None (General Farm)', style: TextStyle(color: AppTheme.textSecondary))),
                      ...sheepList.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.tagNumber} - ${s.name.isNotEmpty ? s.name : "Sheep"}', style: const TextStyle(color: AppTheme.textPrimary)),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => selectedSheepId = val),
                  ),
                  const SizedBox(height: 12),

                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: transactionDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => transactionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(transactionDate),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim());
                        if (amt == null || amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppTheme.accentRed),
                          );
                          return;
                        }

                        final desc = descController.text.trim().isNotEmpty
                            ? descController.text.trim()
                            : selectedCategory;

                        final newRecord = FinancialRecord(
                          id: const Uuid().v4(),
                          type: selectedType,
                          category: selectedCategory,
                          description: desc,
                          amount: amt,
                          date: transactionDate,
                          sheepId: selectedSheepId,
                          notes: notesController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await context.read<FinanceProvider>().addRecord(newRecord);
                        if (mounted) {
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved $selectedType: PKR ${amt.toStringAsFixed(0)}'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Transaction'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ManageCategoriesSheet(
        incomeCategories: List<String>.from(_incomeCategories),
        expenseCategories: List<String>.from(_expenseCategories),
        onSave: (income, expense) {
          setState(() {
            _incomeCategories = income;
            _expenseCategories = expense;
          });
        },
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Entry', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to delete this financial record?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FinanceProvider>().deleteRecord(id);
    }
  }
}

// ── Manage Categories Bottom Sheet ──────────────────────────────────────────

class _ManageCategoriesSheet extends StatefulWidget {
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final void Function(List<String> income, List<String> expense) onSave;

  const _ManageCategoriesSheet({
    required this.incomeCategories,
    required this.expenseCategories,
    required this.onSave,
  });

  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<String> _income;
  late List<String> _expense;
  final _newCatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _income = List<String>.from(widget.incomeCategories);
    _expense = List<String>.from(widget.expenseCategories);
  }

  @override
  void dispose() {
    _tab.dispose();
    _newCatController.dispose();
    super.dispose();
  }

  List<String> get _current => _tab.index == 0 ? _income : _expense;

  void _addCategory() {
    final name = _newCatController.text.trim();
    if (name.isEmpty) return;
    if (_current.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }
    setState(() {
      if (_tab.index == 0) {
        _income.add(name);
      } else {
        _expense.add(name);
      }
      _newCatController.clear();
    });
  }

  void _removeCategory(String name) {
    setState(() {
      if (_tab.index == 0) {
        _income.remove(name);
      } else {
        _expense.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Categories',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () {
                  widget.onSave(_income, _expense);
                  Navigator.pop(context);
                },
                child: const Text('Done', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TabBar(
            controller: _tab,
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            onTap: (_) => setState(() {}),
            tabs: const [Tab(text: 'Income'), Tab(text: 'Expense')],
          ),
          const SizedBox(height: 12),
          // Add new category row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCatController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onSubmitted: (_) => _addCategory(),
                  decoration: InputDecoration(
                    hintText: 'New category name...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.primaryLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add_rounded, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category list — limit height so it scrolls nicely
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _current.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No categories. Add one above.', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _current.length,
                    itemBuilder: (ctx, i) {
                      final cat = _current[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        leading: const Icon(Icons.label_outline_rounded, color: AppTheme.accent, size: 18),
                        title: Text(cat, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 18),
                          onPressed: () => _removeCategory(cat),
                          tooltip: 'Remove',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
