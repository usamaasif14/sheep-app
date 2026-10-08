// sheep_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
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
  late TabController _tab;
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.sheep;
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_appBar(ctx)],
        body: TabBarView(controller: _tab, children: [
          _overviewTab(),
          _healthTab(),
          _weightTab(),
          _breedingTab(),
          _offspringTab(),
          _eventsTab(),
        ]),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────
  Widget _appBar(BuildContext context) {
    final color = _animal.gender == 'Female' ? const Color(0xFFEC407A) : AppTheme.accentBlue;
    return SliverAppBar(
      expandedHeight: 250,
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
            await Navigator.push(context, MaterialPageRoute(builder: (_) => AddSheepScreen(sheep: _animal)));
            await _refresh();
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
              colors: [color.withOpacity(0.18), AppTheme.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Hero(
                    tag: 'animal-${_animal.id}',
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15), shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.5), width: 3),
                      ),
                      child: _animal.photoPath != null
                          ? ClipOval(child: Image.file(File(_animal.photoPath!), fit: BoxFit.cover))
                          : Icon(Icons.pets_rounded, size: 40, color: color),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _badge(_animal.tagNumber, AppTheme.accent),
                      const SizedBox(width: 6),
                      _badge(_animal.animalType, AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Icon(_animal.gender == 'Female' ? Icons.female_rounded : Icons.male_rounded, color: color, size: 18),
                    ]),
                    const SizedBox(height: 4),
                    Text(_animal.name.isEmpty ? '(No name)' : _animal.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(_animal.breed.isEmpty ? 'Unknown breed' : _animal.breed,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _statusBadge(_animal.status),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_animal.stage, style: const TextStyle(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 12),
                // Status action buttons (only for females)
                if (_animal.gender == 'Female') _statusActions(context),
              ]),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AppTheme.accent,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'), Tab(text: 'Health'), Tab(text: 'Weight'),
          Tab(text: 'Breeding'), Tab(text: 'Offspring'), Tab(text: 'Events'),
        ],
      ),
    );
  }

  // ── Status action buttons ────────────────────────────────────────
  Widget _statusActions(BuildContext context) {
    if (_animal.status == 'Active' || _animal.status == 'Gave Birth') {
      return _actionBtn('🤰 Mark as Pregnant', const Color(0xFFEC407A), () => _updateStatus(context, 'Pregnant'));
    }
    if (_animal.status == 'Pregnant') {
      return Row(children: [
        Expanded(child: _actionBtn('🐣 Gave Birth', AppTheme.accentGreen, () => _handleGaveBirth(context))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn('↩ Not Pregnant', AppTheme.textMuted, () => _updateStatus(context, 'Active'))),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final updated = _animal.copyWith(status: newStatus, lastUpdated: DateTime.now());
    await context.read<SheepProvider>().updateSheep(updated);
    setState(() => _animal = updated);
  }

  Future<void> _handleGaveBirth(BuildContext context) async {
    // Update mother status
    await _updateStatus(context, 'Gave Birth');
    if (!mounted) return;
    // Open add baby form pre-filled with mother info
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSheepScreen(
          prefillMother: _animal,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _refresh() async {
    final fresh = await DatabaseService().getAnimalById(_animal.id);
    if (fresh != null && mounted) setState(() => _animal = fresh);
    if (mounted) context.read<SheepProvider>().loadSheep();
  }

  // ── Overview tab ──────────────────────────────────────────────────
  Widget _overviewTab() {
    final infos = [
      _Info('Tag', _animal.tagNumber, Icons.label_rounded),
      _Info('Type', _animal.animalType, Icons.pets_rounded),
      _Info('Gender', _animal.gender, Icons.wc_rounded),
      _Info('Stage', _animal.stage, Icons.auto_graph_rounded),
      _Info('Breed', _animal.breed.isEmpty ? '—' : _animal.breed, Icons.category_rounded),
      _Info('Color', _animal.color.isEmpty ? '—' : _animal.color, Icons.color_lens_rounded),
      _Info('Age', _animal.ageDisplay, Icons.cake_rounded),
      _Info('Weight', '${_animal.weight} kg', Icons.monitor_weight_rounded),
      _Info('DOB', DateFormat('d MMM yyyy').format(_animal.dateOfBirth), Icons.calendar_today_rounded),
      if (_animal.purchaseCost != null) _Info('Cost', 'PKR ${_animal.purchaseCost!.toStringAsFixed(0)}', Icons.currency_rupee_rounded),
      if (_animal.birthLocation?.isNotEmpty == true) _Info('Location', _animal.birthLocation!, Icons.location_on_rounded),
      if (_animal.groupOwner?.isNotEmpty == true) _Info('Owner/Group', _animal.groupOwner!, Icons.group_rounded),
      if (_animal.motherName?.isNotEmpty == true) _Info('Mother', _animal.motherName!, Icons.female_rounded),
      _Info('Added', DateFormat('d MMM yyyy').format(_animal.dateAdded), Icons.add_circle_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
          itemCount: infos.length,
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
            child: Row(children: [
              Icon(infos[i].icon, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(infos[i].label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                Text(infos[i].value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        ),
        if (_animal.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.notes_rounded, color: AppTheme.accent, size: 16),
                SizedBox(width: 8),
                Text('Notes', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Text(_animal.notes!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Health tab ────────────────────────────────────────────────────
  Widget _healthTab() {
    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getHealthRecords(_animal.id),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _empty('No health records yet', 'Add vaccinations, treatments and checkups', Icons.medical_services_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (_, i) => _healthCard(records[i]).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent, foregroundColor: AppTheme.primaryDark,
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddHealthRecordScreen(sheepId: _animal.id, sheepName: _animal.name.isEmpty ? _animal.tagNumber : _animal.name)))
                .then((_) => setState(() {})),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _healthCard(HealthRecord r) {
    final colors = {'Vaccination': AppTheme.accentBlue, 'Treatment': AppTheme.accentRed, 'Checkup': AppTheme.accentGreen, 'Deworming': AppTheme.accent};
    final c = colors[r.type] ?? AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.medical_services_rounded, color: c, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(r.type, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
            Text(DateFormat('d MMM yyyy').format(r.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ]),
          Text(r.description, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
          if (r.medicine != null) Text('Medicine: ${r.medicine}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          if (r.nextDueDate != null) Text('Next due: ${DateFormat('d MMM yyyy').format(r.nextDueDate!)}', style: const TextStyle(color: AppTheme.accentRed, fontSize: 11)),
        ])),
      ]),
    );
  }

  // ── Weight tab ────────────────────────────────────────────────────
  Widget _weightTab() {
    return FutureBuilder<List<WeightRecord>>(
      future: context.read<SheepProvider>().getWeightHistory(_animal.id),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: records.isEmpty
              ? _empty('No weight records', 'Track weight gain over time', Icons.monitor_weight_rounded)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    if (records.length >= 2)
                      Container(
                        height: 200, padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
                        child: LineChart(LineChartData(
                          lineBarsData: [LineChartBarData(
                            spots: records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList(),
                            isCurved: true, color: AppTheme.accentGreen, barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: AppTheme.accentGreen.withOpacity(0.1)),
                          )],
                          gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.cardBorder, strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.cardBorder, strokeWidth: 1)),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                        )),
                      ),
                    const SizedBox(height: 16),
                    ...records.reversed.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.monitor_weight_rounded, color: AppTheme.accentGreen, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${r.weight} kg', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(DateFormat('d MMM yyyy').format(r.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ])),
                      ]),
                    )),
                  ]),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent, foregroundColor: AppTheme.primaryDark,
            onPressed: _addWeight, child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  // ── Breeding tab ──────────────────────────────────────────────────
  Widget _breedingTab() {
    return FutureBuilder<List<BreedingRecord>>(
      future: context.read<SheepProvider>().getBreedingRecords(_animal.id),
      builder: (_, snap) {
        final records = snap.data ?? [];
        return records.isEmpty
            ? _empty('No breeding records', 'Track mating and offspring', Icons.favorite_rounded)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (_, i) => _breedingCard(records[i]),
              );
      },
    );
  }

  Widget _breedingCard(BreedingRecord r) {
    final statusColors = {'Mated': AppTheme.accent, 'Pregnant': const Color(0xFFEC407A), 'Lambed': AppTheme.accentGreen, 'Failed': AppTheme.accentRed};
    final c = statusColors[r.status] ?? AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Mating: ${DateFormat('d MMM yyyy').format(r.matingDate)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(r.status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        if (r.expectedLambingDate != null) ...[
          const SizedBox(height: 4),
          Text('Expected birth: ${DateFormat('d MMM yyyy').format(r.expectedLambingDate!)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
        if (r.lambsBorn != null) ...[
          const SizedBox(height: 4),
          Text('Born: ${r.lambsBorn} | Survived: ${r.lambsSurvived ?? 0}', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  // ── Offspring tab ─────────────────────────────────────────────────
  Widget _offspringTab() {
    return FutureBuilder<List<Animal>>(
      future: context.read<SheepProvider>().getOffspring(_animal.id),
      builder: (_, snap) {
        final list = snap.data ?? [];
        return list.isEmpty
            ? _empty('No offspring recorded', 'Offspring appear here when this animal is set as a parent', Icons.child_care_rounded)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final o = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.child_care_rounded, color: AppTheme.accentGreen, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${o.tagNumber}${o.name.isNotEmpty ? " — ${o.name}" : ""}',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        Text('${o.animalType} · ${o.gender} · ${o.stage} · ${o.ageDisplay}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text(o.motherId == _animal.id ? 'Mother: this animal' : 'Father: this animal',
                            style: const TextStyle(color: AppTheme.accent, fontSize: 11)),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SheepDetailScreen(sheep: o))),
                      ),
                    ]),
                  );
                },
              );
      },
    );
  }

  // ── Events tab ────────────────────────────────────────────────────
  Widget _eventsTab() {
    return FutureBuilder<List<AnimalEvent>>(
      future: context.read<SheepProvider>().getEvents(_animal.id),
      builder: (ctx, snap) {
        final events = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          body: events.isEmpty
              ? _empty('No events yet', 'Log shearing, sale attempts, notes and more', Icons.event_note_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _eventCard(events[i]).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent, foregroundColor: AppTheme.primaryDark,
            onPressed: () => _showEventDialog(context),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _eventCard(AnimalEvent e) {
    final typeColors = {
      'Note': AppTheme.textSecondary, 'Weight Check': AppTheme.accentGreen,
      'Shearing': AppTheme.accentBlue, 'Sale Attempt': AppTheme.accent,
      'Medication': AppTheme.accentRed, 'Other': AppTheme.textMuted,
    };
    final c = typeColors[e.eventType] ?? AppTheme.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.event_note_rounded, size: 18, color: AppTheme.accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.eventType, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(DateFormat('d MMM yyyy').format(e.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ]),
          Text(e.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          if (e.description?.isNotEmpty == true) Text(e.description!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (e.cost != null) Text('Cost: PKR ${e.cost!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentRed, fontSize: 11)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 18),
          color: AppTheme.cardBg,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppTheme.textPrimary))),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.accentRed))),
          ],
          onSelected: (v) async {
            if (v == 'delete') {
              await context.read<SheepProvider>().deleteEvent(e.id);
              setState(() {});
            } else if (v == 'edit') {
              await _showEventDialog(context, existing: e);
            }
          },
        ),
      ]),
    );
  }

  Future<void> _showEventDialog(BuildContext context, {AnimalEvent? existing}) async {
    final types = ['Note', 'Weight Check', 'Shearing', 'Sale Attempt', 'Medication', 'Other'];
    String selectedType = existing?.eventType ?? 'Note';
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final costCtrl = TextEditingController(text: existing?.cost?.toStringAsFixed(0) ?? '');
    DateTime date = existing?.date ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(existing == null ? 'Add Event' : 'Edit Event',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: AppTheme.cardBg,
                decoration: const InputDecoration(labelText: 'Event Type', prefixIcon: Icon(Icons.category_rounded)),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                onChanged: (v) => setS(() => selectedType = v ?? 'Note'),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title_rounded))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description (Optional)', prefixIcon: Icon(Icons.notes_rounded))),
              const SizedBox(height: 12),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Cost PKR (Optional)', prefixIcon: Icon(Icons.currency_rupee_rounded))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (c, child) => Theme(data: AppTheme.darkTheme, child: child!));
                  if (d != null) setS(() => date = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      Text(DateFormat('d MMMM yyyy').format(date), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final provider = context.read<SheepProvider>();
                    if (existing == null) {
                      await provider.addEvent(AnimalEvent(
                        id: const Uuid().v4(), animalId: _animal.id,
                        eventType: selectedType, title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        date: date, cost: double.tryParse(costCtrl.text),
                        createdAt: DateTime.now(),
                      ));
                    } else {
                      final updated = AnimalEvent(
                        id: existing.id, animalId: existing.animalId,
                        eventType: selectedType, title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        date: date, cost: double.tryParse(costCtrl.text),
                        createdAt: existing.createdAt,
                      );
                      await provider.updateEvent(updated);
                    }
                    if (mounted) { Navigator.pop(ctx); setState(() {}); }
                  },
                  child: Text(existing == null ? 'Save Event' : 'Update Event'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _empty(String title, String sub, IconData icon) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: AppTheme.textMuted),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
    ]),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
  );

  Widget _statusBadge(String status) {
    final colors = {'Active': AppTheme.accentGreen, 'Pregnant': const Color(0xFFEC407A), 'Gave Birth': AppTheme.accentGreen, 'Sold': AppTheme.accentBlue, 'Deceased': AppTheme.accentRed, 'Quarantine': AppTheme.accent};
    final c = colors[status] ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _addWeight() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context, backgroundColor: AppTheme.cardBg, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Weight Record', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(ctrl.text);
              if (w == null) return;
              await context.read<SheepProvider>().addWeightRecord(WeightRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), sheepId: _animal.id, weight: w, date: DateTime.now()));
              if (mounted) { Navigator.pop(ctx); setState(() {}); }
            },
            child: const Text('Save'),
          )),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Animal', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove ${_animal.name.isEmpty ? _animal.tagNumber : _animal.name}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SheepProvider>().deleteSheep(_animal.id);
      Navigator.pop(context);
    }
  }
}

class _Info { final String label, value; final IconData icon; _Info(this.label, this.value, this.icon); }
