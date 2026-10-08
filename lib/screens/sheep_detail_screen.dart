// sheep_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/animal_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import 'add_sheep_screen.dart';
import 'add_health_record_screen.dart';

class SheepDetailScreen extends StatefulWidget {
  final Animal sheep;
  const SheepDetailScreen({super.key, required this.sheep});
  @override
  State<SheepDetailScreen> createState() => _SheepDetailScreenState();
}

class _SheepDetailScreenState extends State<SheepDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.sheep;
    _tabController = TabController(length: 5, vsync: this);
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
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar(ctx)],
        body: TabBarView(controller: _tabController, children: [
          _buildOverviewTab(),
          _buildHealthTab(),
          _buildWeightTab(),
          _buildBreedingTab(),
          _buildOffspringTab(),
        ]),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final color =
        _animal.gender == 'Female' ? const Color(0xFFEC407A) : AppTheme.accentBlue;

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: AppTheme.accent),
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddSheepScreen(sheep: _animal)));
            if (mounted) {
              final updated = await context.read<SheepProvider>().getHealthRecords(_animal.id);
              setState(() {});
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_rounded, color: AppTheme.accentRed),
          onPressed: () => _confirmDelete(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.15), AppTheme.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: Row(children: [
                // Photo
                Hero(
                  tag: 'animal-${_animal.id}',
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.5), width: 3),
                    ),
                    child: _animal.photoPath != null
                        ? ClipOval(
                            child: Image.file(File(_animal.photoPath!),
                                fit: BoxFit.cover))
                        : Icon(Icons.pets_rounded, size: 44, color: color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_animal.tagNumber,
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_animal.animalType,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _animal.gender == 'Female'
                              ? Icons.female_rounded
                              : Icons.male_rounded,
                          color: color, size: 18),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        _animal.name.isEmpty ? '(No name)' : _animal.name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _animal.breed.isEmpty ? 'Unknown breed' : _animal.breed,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      _statusBadge(_animal.status),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accent,
        indicatorWeight: 3,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Health'),
          Tab(text: 'Weight'),
          Tab(text: 'Breeding'),
          Tab(text: 'Offspring'),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'Active': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    final c = colors[status] ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(status,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final infos = [
      _Info('Tag', _animal.tagNumber, Icons.label_rounded),
      _Info('Type', _animal.animalType, Icons.pets_rounded),
      _Info('Gender', _animal.gender, Icons.wc_rounded),
      _Info('Breed', _animal.breed.isEmpty ? '—' : _animal.breed, Icons.category_rounded),
      _Info('Color', _animal.color.isEmpty ? '—' : _animal.color, Icons.color_lens_rounded),
      _Info('Age', _animal.ageDisplay, Icons.cake_rounded),
      _Info('Weight', '${_animal.weight} kg', Icons.monitor_weight_rounded),
      _Info('DOB', DateFormat('d MMM yyyy').format(_animal.dateOfBirth), Icons.calendar_today_rounded),
      if (_animal.purchaseCost != null)
        _Info('Cost', 'Rs ${_animal.purchaseCost!.toStringAsFixed(0)}', Icons.currency_rupee_rounded),
      if (_animal.birthLocation != null && _animal.birthLocation!.isNotEmpty)
        _Info('Location', _animal.birthLocation!, Icons.location_on_rounded),
      if (_animal.groupOwner != null && _animal.groupOwner!.isNotEmpty)
        _Info('Group/Owner', _animal.groupOwner!, Icons.group_rounded),
      _Info('Added', DateFormat('d MMM yyyy').format(_animal.dateAdded), Icons.add_circle_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: infos.length,
          itemBuilder: (ctx, i) {
            final info = infos[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(children: [
                Icon(info.icon, size: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(info.label,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                      Text(info.value,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
        if (_animal.notes != null && _animal.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.notes_rounded, color: AppTheme.accent, size: 16),
                SizedBox(width: 8),
                Text('Notes',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Text(_animal.notes!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Health tab ────────────────────────────────────────────────────
  Widget _buildHealthTab() {
    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getHealthRecords(_animal.id),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _emptyTab('No health records yet',
                  'Add vaccinations, treatments and checkups',
                  Icons.medical_services_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (c, i) =>
                      _healthCard(records[i])
                          .animate(delay: Duration(milliseconds: i * 50))
                          .fadeIn(),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.primaryDark,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddHealthRecordScreen(
                      sheepId: _animal.id,
                      sheepName: _animal.name.isEmpty
                          ? _animal.tagNumber
                          : _animal.name)),
            ).then((_) => setState(() {})),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _healthCard(HealthRecord r) {
    final colors = {
      'Vaccination': AppTheme.accentBlue,
      'Treatment': AppTheme.accentRed,
      'Checkup': AppTheme.accentGreen,
      'Deworming': AppTheme.accent,
    };
    final c = colors[r.type] ?? AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.medical_services_rounded, color: c, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.type,
                    style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text(DateFormat('d MMM yyyy').format(r.date),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            Text(r.description,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
            if (r.medicine != null)
              Text('Medicine: ${r.medicine}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
            if (r.nextDueDate != null)
              Text(
                  'Next due: ${DateFormat('d MMM yyyy').format(r.nextDueDate!)}',
                  style: const TextStyle(
                      color: AppTheme.accentRed, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  // ── Weight tab ────────────────────────────────────────────────────
  Widget _buildWeightTab() {
    return FutureBuilder<List<WeightRecord>>(
      future: context.read<SheepProvider>().getWeightHistory(_animal.id),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _emptyTab('No weight records',
                  'Track weight gain over time',
                  Icons.monitor_weight_rounded)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Chart
                    if (records.length >= 2)
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: LineChart(LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: records
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(
                                      e.key.toDouble(), e.value.weight))
                                  .toList(),
                              isCurved: true,
                              color: AppTheme.accentGreen,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.accentGreen.withOpacity(0.1)),
                            ),
                          ],
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) => FlLine(
                                color: AppTheme.cardBorder, strokeWidth: 1),
                            getDrawingVerticalLine: (_) => FlLine(
                                color: AppTheme.cardBorder, strokeWidth: 1),
                          ),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true, reservedSize: 40)),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                        )),
                      ),
                    const SizedBox(height: 16),
                    ...records.reversed.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.monitor_weight_rounded,
                                  color: AppTheme.accentGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${r.weight} kg',
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  Text(
                                      DateFormat('d MMM yyyy').format(r.date),
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ]),
                        )),
                  ]),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.primaryDark,
            onPressed: _addWeight,
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  // ── Breeding tab ──────────────────────────────────────────────────
  Widget _buildBreedingTab() {
    return FutureBuilder<List<BreedingRecord>>(
      future:
          context.read<SheepProvider>().getBreedingRecords(_animal.id),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        return records.isEmpty
            ? _emptyTab('No breeding records',
                'Track mating and offspring events',
                Icons.favorite_rounded)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (c, i) => _breedingCard(records[i]),
              );
      },
    );
  }

  Widget _breedingCard(BreedingRecord r) {
    final statusColors = {
      'Mated': AppTheme.accent,
      'Pregnant': const Color(0xFFEC407A),
      'Lambed': AppTheme.accentGreen,
      'Failed': AppTheme.accentRed,
    };
    final c = statusColors[r.status] ?? AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                'Mating: ${DateFormat('d MMM yyyy').format(r.matingDate)}',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(r.status,
                  style: TextStyle(
                      color: c,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (r.expectedLambingDate != null) ...[
          const SizedBox(height: 4),
          Text(
              'Expected birth: ${DateFormat('d MMM yyyy').format(r.expectedLambingDate!)}',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12)),
        ],
        if (r.lambsBorn != null) ...[
          const SizedBox(height: 4),
          Text(
              'Born: ${r.lambsBorn} | Survived: ${r.lambsSurvived ?? 0}',
              style: const TextStyle(
                  color: AppTheme.accentGreen, fontSize: 12)),
        ],
      ]),
    );
  }

  // ── Offspring tab ─────────────────────────────────────────────────
  Widget _buildOffspringTab() {
    return FutureBuilder<List<Animal>>(
      future: context.read<SheepProvider>().getOffspring(_animal.id),
      builder: (ctx, snap) {
        final offspring = snap.data ?? [];
        return offspring.isEmpty
            ? _emptyTab('No offspring recorded',
                'Offspring appear here when you set this animal as a parent',
                Icons.child_care_rounded)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offspring.length,
                itemBuilder: (c, i) {
                  final o = offspring[i];
                  final isChild = o.motherId == _animal.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.child_care_rounded,
                            color: AppTheme.accentGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${o.tagNumber}${o.name.isNotEmpty ? " — ${o.name}" : ""}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${o.animalType} • ${o.gender} • ${o.ageDisplay}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                            Text(
                              isChild ? 'Mother: this animal' : 'Father: this animal',
                              style: const TextStyle(
                                  color: AppTheme.accent, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textMuted),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SheepDetailScreen(sheep: o)),
                        ),
                      ),
                    ]),
                  );
                },
              );
      },
    );
  }

  Widget _emptyTab(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: AppTheme.textMuted),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13)),
        ),
      ]),
    );
  }

  Future<void> _addWeight() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Weight Record',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
                labelText: 'Weight (kg)', suffixText: 'kg'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final w = double.tryParse(ctrl.text);
                if (w == null) return;
                await context.read<SheepProvider>().addWeightRecord(
                    WeightRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        sheepId: _animal.id,
                        weight: w,
                        date: DateTime.now()));
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Animal',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            'Remove ${_animal.name.isEmpty ? _animal.tagNumber : _animal.name}?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SheepProvider>().deleteSheep(_animal.id);
      Navigator.pop(context);
    }
  }
}

class _Info {
  final String label, value;
  final IconData icon;
  _Info(this.label, this.value, this.icon);
}
