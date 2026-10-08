// sheep_detail_screen.dart - Full sheep profile with tabs
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import '../models/sheep_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import 'add_sheep_screen.dart';
import 'add_health_record_screen.dart';

class SheepDetailScreen extends StatefulWidget {
  final Sheep sheep;

  const SheepDetailScreen({super.key, required this.sheep});

  @override
  State<SheepDetailScreen> createState() => _SheepDetailScreenState();
}

class _SheepDetailScreenState extends State<SheepDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Sheep _sheep;

  @override
  void initState() {
    super.initState();
    _sheep = widget.sheep;
    _tabController = TabController(length: 4, vsync: this);
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
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildHealthTab(),
            _buildWeightTab(),
            _buildBreedingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final color = _sheep.gender == 'Female'
        ? const Color(0xFFEC407A)
        : AppTheme.accentBlue;

    return SliverAppBar(
      expandedHeight: 220,
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddSheepScreen(sheep: _sheep)),
            );
            // Refresh sheep after edit
            final updated = await context.read<SheepProvider>().getHealthRecords(_sheep.id);
            setState(() {});
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
              child: Row(
                children: [
                  // Photo or avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.5), width: 3),
                    ),
                    child: _sheep.photoPath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_sheep.photoPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.pets_rounded, size: 44, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _sheep.tagNumber,
                                style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _sheep.gender == 'Female'
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              color: color,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sheep.name.isEmpty ? '(No name)' : _sheep.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _sheep.breed.isEmpty ? 'Unknown breed' : _sheep.breed,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        _buildStatusBadge(_sheep.status),
                      ],
                    ),
                  ),
                ],
              ),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Health'),
          Tab(text: 'Weight'),
          Tab(text: 'Breeding'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'Active': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    final color = colors[status] ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoGrid(sheep: _sheep),
          const SizedBox(height: 16),
          if (_sheep.notes != null && _sheep.notes!.isNotEmpty)
            _NotesCard(notes: _sheep.notes!),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getHealthRecords(_sheep.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _buildEmptyTabState(
                  'No health records yet',
                  'Add vaccinations, treatments and checkups',
                  Icons.medical_services_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) =>
                      _HealthRecordCard(record: records[i]).animate(delay: Duration(milliseconds: i * 50)).fadeIn(),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddHealthRecordScreen(sheepId: _sheep.id),
              ),
            ).then((_) => setState(() {})),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _buildWeightTab() {
    return FutureBuilder<List<WeightRecord>>(
      future: context.read<SheepProvider>().getWeightHistory(_sheep.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _buildEmptyTabState(
                  'No weight records',
                  'Track weight gain over time',
                  Icons.monitor_weight_rounded)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Weight chart
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: _buildWeightChart(records),
                      ),
                      const SizedBox(height: 16),
                      // Weight history list
                      ...records.reversed.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.monitor_weight_rounded,
                                      color: AppTheme.accentGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.weight} kg',
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        DateFormat('d MMM yyyy').format(r.date),
                                        style: const TextStyle(
                                            color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addWeightRecord(),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _buildWeightChart(List<WeightRecord> records) {
    if (records.length < 2) {
      return const Center(
        child: Text('Add more records to see chart',
            style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: records.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.weight);
            }).toList(),
            isCurved: true,
            color: AppTheme.accentGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentGreen.withOpacity(0.1),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBreedingTab() {
    return FutureBuilder<List<BreedingRecord>>(
      future: context.read<SheepProvider>().getBreedingRecords(_sheep.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        return records.isEmpty
            ? _buildEmptyTabState(
                'No breeding records',
                'Track mating and lambing events',
                Icons.favorite_rounded)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (ctx, i) => _BreedingRecordCard(record: records[i]),
              );
      },
    );
  }

  Widget _buildEmptyTabState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _addWeightRecord() async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Weight Record',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final weight = double.tryParse(controller.text);
                  if (weight == null) return;
                  final record = WeightRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    sheepId: _sheep.id,
                    weight: weight,
                    date: DateTime.now(),
                  );
                  await context.read<SheepProvider>().addWeightRecord(record);
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Sheep',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            'Are you sure you want to remove ${_sheep.name.isEmpty ? _sheep.tagNumber : _sheep.name} from your flock?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SheepProvider>().deleteSheep(_sheep.id);
      Navigator.pop(context);
    }
  }
}

class _InfoGrid extends StatelessWidget {
  final Sheep sheep;
  const _InfoGrid({required this.sheep});

  @override
  Widget build(BuildContext context) {
    final infos = [
      _Info('Tag', sheep.tagNumber, Icons.label_rounded),
      _Info('Gender', sheep.gender, Icons.wc_rounded),
      _Info('Breed', sheep.breed.isEmpty ? '—' : sheep.breed, Icons.category_rounded),
      _Info('Color', sheep.color.isEmpty ? '—' : sheep.color, Icons.color_lens_rounded),
      _Info('Age', sheep.ageDisplay, Icons.cake_rounded),
      _Info('Weight', '${sheep.weight} kg', Icons.monitor_weight_rounded),
      _Info('DOB', DateFormat('d MMM yyyy').format(sheep.dateOfBirth), Icons.calendar_today_rounded),
      _Info('Added', DateFormat('d MMM yyyy').format(sheep.dateAdded), Icons.add_circle_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: infos.length,
      itemBuilder: (context, i) {
        final info = infos[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
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
            ],
          ),
        );
      },
    );
  }
}

class _Info {
  final String label;
  final String value;
  final IconData icon;
  _Info(this.label, this.value, this.icon);
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppTheme.accent, size: 16),
              SizedBox(width: 8),
              Text('Notes',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(notes,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  const _HealthRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Vaccination': AppTheme.accentBlue,
      'Treatment': AppTheme.accentRed,
      'Checkup': AppTheme.accentGreen,
      'Deworming': AppTheme.accent,
    };
    final color = colors[record.type] ?? AppTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.medical_services_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(record.type,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    Text(DateFormat('d MMM yyyy').format(record.date),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(record.description,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                if (record.medicine != null)
                  Text('Medicine: ${record.medicine}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                if (record.nextDueDate != null)
                  Text(
                      'Next due: ${DateFormat('d MMM yyyy').format(record.nextDueDate!)}',
                      style: const TextStyle(
                          color: AppTheme.accentRed, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedingRecordCard extends StatelessWidget {
  final BreedingRecord record;
  const _BreedingRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'Mated': AppTheme.accent,
      'Pregnant': const Color(0xFFEC407A),
      'Lambed': AppTheme.accentGreen,
      'Failed': AppTheme.accentRed,
    };
    final color = statusColors[record.status] ?? AppTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mating: ${DateFormat('d MMM yyyy').format(record.matingDate)}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(record.status,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (record.expectedLambingDate != null) ...[
            const SizedBox(height: 4),
            Text(
                'Expected lambing: ${DateFormat('d MMM yyyy').format(record.expectedLambingDate!)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
          if (record.lambsBorn != null) ...[
            const SizedBox(height: 4),
            Text(
                'Lambs born: ${record.lambsBorn} | Survived: ${record.lambsSurvived ?? 0}',
                style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
