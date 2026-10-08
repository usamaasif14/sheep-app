// breeding_screen.dart - Breeding and lambing management
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/breeding_model.dart';
import '../models/sheep_model.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';
import '../services/database_service.dart';
import '../widgets/section_header.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final _db = DatabaseService();
  List<BreedingRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    _records = await _db.getAllBreedingRecords();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            title: const Text('Breeding Records',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildBreedingStats(),
                const SizedBox(height: 20),
                _buildPregnantAnimalsSection(),
                const SizedBox(height: 16),
                const SectionHeader(
                    title: 'Breeding History', icon: Icons.history_rounded),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent)))
          else if (_records.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BreedingCard(record: _records[i]),
                  childCount: _records.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBreedingDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Mating', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBreedingStats() {
    final pregnant = _records.where((r) => r.status == 'Pregnant').length;
    final lambed = _records.where((r) => r.status == 'Lambed').length;
    final totalLambs = _records.fold<int>(0, (sum, r) => sum + (r.lambsSurvived ?? 0));

    return Row(
      children: [
        _StatTile(
          label: 'Pregnant',
          value: pregnant.toString(),
          color: const Color(0xFFEC407A),
          icon: Icons.pregnant_woman_rounded,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Lambed',
          value: lambed.toString(),
          color: AppTheme.accentGreen,
          icon: Icons.pets_rounded,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Total Lambs',
          value: totalLambs.toString(),
          color: AppTheme.accentBlue,
          icon: Icons.child_care_rounded,
        ),
      ],
    );
  }

  Widget _buildPregnantAnimalsSection() {
    return Consumer<SheepProvider>(
      builder: (context, provider, _) {
        final pregnant = provider.allAnimals.where((a) => a.status == 'Pregnant').toList();
        if (pregnant.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.pregnant_woman_rounded, color: Color(0xFFEC407A), size: 18),
              const SizedBox(width: 8),
              Text('Pregnant (${pregnant.length})', style: const TextStyle(color: Color(0xFFEC407A), fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            ...pregnant.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEC407A).withOpacity(0.35)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEC407A).withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.pregnant_woman_rounded, color: Color(0xFFEC407A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a.tagNumber}${a.name.isNotEmpty ? " — ${a.name}" : ""}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${a.animalType} · ${a.breed.isEmpty ? "Unknown breed" : a.breed} · ${a.ageDisplay}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEC407A).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('🤰 Pregnant', style: TextStyle(color: Color(0xFFEC407A), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFEC407A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 56, color: Color(0xFFEC407A)),
          ),
          const SizedBox(height: 20),
          const Text('No Breeding Records',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Log mating events to track lambing',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _showAddBreedingDialog(BuildContext context) async {
    final sheep = context.read<SheepProvider>().allSheep;
    final ewes = sheep.where((s) => s.gender == 'Female' && s.status == 'Active').toList();
    final rams = sheep.where((s) => s.gender == 'Male' && s.status == 'Active').toList();

    String? selectedEweId;
    String? selectedRamId;
    DateTime matingDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Log Mating Event',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ),
              const SizedBox(height: 20),
              // Ewe selector
              DropdownButtonFormField<String>(
                value: selectedEweId,
                hint: const Text('Select Ewe (Female)'),
                decoration: InputDecoration(
                  labelText: 'Ewe *',
                  prefixIcon: const Icon(Icons.female_rounded,
                      color: Color(0xFFEC407A)),
                  filled: true,
                  fillColor: AppTheme.primaryLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: AppTheme.cardBg,
                items: ewes
                    .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text('${e.tagNumber} - ${e.name.isEmpty ? e.breed : e.name}')))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedEweId = v),
              ),
              const SizedBox(height: 12),
              // Ram selector
              DropdownButtonFormField<String>(
                value: selectedRamId,
                hint: const Text('Select Ram (Male) - Optional'),
                decoration: InputDecoration(
                  labelText: 'Ram',
                  prefixIcon:
                      const Icon(Icons.male_rounded, color: AppTheme.accentBlue),
                  filled: true,
                  fillColor: AppTheme.primaryLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: AppTheme.cardBg,
                items: rams
                    .map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text('${r.tagNumber} - ${r.name.isEmpty ? r.breed : r.name}')))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedRamId = v),
              ),
              const SizedBox(height: 12),
              // Mating date
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: matingDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (c, child) =>
                        Theme(data: AppTheme.darkTheme, child: child!),
                  );
                  if (d != null) setModalState(() => matingDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mating Date',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                          Text(DateFormat('d MMMM yyyy').format(matingDate),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC407A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedEweId == null
                      ? null
                      : () async {
                          // Calculate expected lambing (average gestation ~147 days)
                          final expectedLambing =
                              matingDate.add(const Duration(days: 147));
                          final record = BreedingRecord(
                            id: const Uuid().v4(),
                            eweId: selectedEweId!,
                            ramId: selectedRamId,
                            matingDate: matingDate,
                            expectedLambingDate: expectedLambing,
                            status: 'Mated',
                            createdAt: DateTime.now(),
                          );
                          await _db.insertBreedingRecord(record);
                          Navigator.pop(ctx);
                          _loadRecords();
                        },
                  child: const Text('Log Mating Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 22)),
            Text(label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BreedingCard extends StatelessWidget {
  final BreedingRecord record;
  const _BreedingCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'Mated': AppTheme.accent,
      'Pregnant': const Color(0xFFEC407A),
      'Lambed': AppTheme.accentGreen,
      'Failed': AppTheme.accentRed,
    };
    final color = statusColors[record.status] ?? AppTheme.accent;
    final db = DatabaseService();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFEC407A), size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(record.status,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<Animal?>(
            future: db.getSheepById(record.eweId),
            builder: (context, snap) {
              final ewe = snap.data;
              return Text(
                'Ewe: ${ewe?.tagNumber ?? '...'} ${ewe?.name.isNotEmpty == true ? '(${ewe!.name})' : ''}',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              );
            },
          ),
          const SizedBox(height: 4),
          Text('Mated: ${DateFormat('d MMM yyyy').format(record.matingDate)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          if (record.expectedLambingDate != null)
            Text(
                'Expected Lambing: ${DateFormat('d MMM yyyy').format(record.expectedLambingDate!)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          if (record.lambsBorn != null) ...[
            const SizedBox(height: 6),
            Text(
                '🐑 Lambs born: ${record.lambsBorn} | Survived: ${record.lambsSurvived ?? 0}',
                style: const TextStyle(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
