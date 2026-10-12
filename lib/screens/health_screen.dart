// health_screen.dart - Health overview for all animals
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sheep_provider.dart';
import '../models/health_model.dart';
import '../models/animal_model.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/section_header.dart';
import 'sheep_detail_screen.dart';
import 'add_health_record_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                Tab(text: 'All Records'),
                Tab(text: 'Flock Summary'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _UpcomingTasksTab(onRefresh: () => setState(() {})),
            _AllHealthRecordsTab(onRefresh: () => setState(() {})),
            const _HealthSummaryTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.primaryDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Health Record', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHealthRecordScreen()),
          );
          if (res == true && mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPCOMING TASKS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingTasksTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _UpcomingTasksTab({required this.onRefresh});

  @override
  State<_UpcomingTasksTab> createState() => _UpcomingTasksTabState();
}

class _UpcomingTasksTabState extends State<_UpcomingTasksTab> {
  final DatabaseService _db = DatabaseService();

  Future<void> _openAnimal(BuildContext context, String sheepId) async {
    final animal = await _db.getAnimalById(sheepId);
    if (!mounted) return;
    if (animal != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SheepDetailScreen(sheep: animal)),
      );
      setState(() {});
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal details could not be found.'), backgroundColor: AppTheme.accentRed),
      );
    }
  }

  Future<void> _editRecord(BuildContext context, HealthRecord record) async {
    final animal = await _db.getAnimalById(record.sheepId);
    if (!mounted) return;
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthRecordScreen(
          sheepId: record.sheepId,
          sheepName: animal != null ? '${animal.tagNumber} - ${animal.name}' : null,
          existingRecord: record,
        ),
      ),
    );
    if (res == true && mounted) {
      setState(() {});
      widget.onRefresh();
    }
  }

  Future<void> _deleteRecord(BuildContext context, HealthRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Health Task', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove "${record.description}"? This cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SheepProvider>().deleteHealthRecord(record.id);
      setState(() {});
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getUpcomingHealthTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
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
                  child: const Icon(Icons.check_circle_rounded, size: 56, color: AppTheme.accentGreen),
                ),
                const SizedBox(height: 16),
                const Text('All clear!',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('No health tasks due in the next 30 days',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: tasks.length,
          itemBuilder: (context, i) {
            final task = tasks[i];
            final daysUntil = task.nextDueDate?.difference(DateTime.now()).inDays ?? 0;
            final isOverdue = daysUntil < 0;
            final isUrgent = daysUntil <= 3;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openAnimal(context, task.sheepId),
              child: Container(
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
                              fontWeight: FontWeight.w700,
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
                          FutureBuilder<Animal?>(
                            future: _db.getAnimalById(task.sheepId),
                            builder: (ctx, snap) {
                              final a = snap.data;
                              if (a == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pets_rounded, size: 12, color: AppTheme.accent),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${a.tagNumber}${a.name.isNotEmpty ? " • ${a.name}" : ""}',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Text(
                            task.description,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(task.type,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              if (task.medicine != null) ...[
                                const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                                Text(task.medicine!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ],
                          ),
                          if (task.nextDueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Due: ${DateFormat('d MMMM yyyy').format(task.nextDueDate!)}',
                                style: TextStyle(
                                  color: isOverdue ? AppTheme.accentRed : AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                      color: AppTheme.cardBg,
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(children: [
                            Icon(Icons.visibility_rounded, color: AppTheme.accent, size: 18),
                            SizedBox(width: 10),
                            Text('View Animal', style: TextStyle(color: AppTheme.textPrimary)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded, color: AppTheme.accentBlue, size: 18),
                            SizedBox(width: 10),
                            Text('Edit Record', style: TextStyle(color: AppTheme.textPrimary)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 18),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
                          ]),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'view') _openAnimal(context, task.sheepId);
                        if (val == 'edit') _editRecord(context, task);
                        if (val == 'delete') _deleteRecord(context, task);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALL HEALTH RECORDS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AllHealthRecordsTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _AllHealthRecordsTab({required this.onRefresh});

  @override
  State<_AllHealthRecordsTab> createState() => _AllHealthRecordsTabState();
}

class _AllHealthRecordsTabState extends State<_AllHealthRecordsTab> {
  final DatabaseService _db = DatabaseService();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Vaccination', 'Treatment', 'Checkup', 'Deworming'];

  Future<void> _openAnimal(BuildContext context, String sheepId) async {
    final animal = await _db.getAnimalById(sheepId);
    if (!mounted) return;
    if (animal != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SheepDetailScreen(sheep: animal)),
      );
      setState(() {});
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal details could not be found.'), backgroundColor: AppTheme.accentRed),
      );
    }
  }

  Future<void> _editRecord(BuildContext context, HealthRecord record) async {
    final animal = await _db.getAnimalById(record.sheepId);
    if (!mounted) return;
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthRecordScreen(
          sheepId: record.sheepId,
          sheepName: animal != null ? '${animal.tagNumber} - ${animal.name}' : null,
          existingRecord: record,
        ),
      ),
    );
    if (res == true && mounted) {
      setState(() {});
      widget.onRefresh();
    }
  }

  Future<void> _deleteRecord(BuildContext context, HealthRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Health Record', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove "${record.description}"? This cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SheepProvider>().deleteHealthRecord(record.id);
      setState(() {});
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      'Vaccination': AppTheme.accentBlue,
      'Treatment': AppTheme.accentRed,
      'Checkup': AppTheme.accentGreen,
      'Deworming': AppTheme.accent,
    };

    return FutureBuilder<List<HealthRecord>>(
      future: context.read<SheepProvider>().getAllHealthRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }

        var records = snapshot.data ?? [];

        if (_selectedFilter != 'All') {
          records = records.where((r) => r.type == _selectedFilter).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          records = records.where((r) {
            return r.description.toLowerCase().contains(q) ||
                (r.medicine ?? '').toLowerCase().contains(q) ||
                (r.veterinarian ?? '').toLowerCase().contains(q);
          }).toList();
        }

        return Column(
          children: [
            // Filter and Search Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search records, medicine, vet...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final isSel = _selectedFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: isSel,
                            selectedColor: AppTheme.accent.withOpacity(0.2),
                            backgroundColor: AppTheme.cardBg,
                            labelStyle: TextStyle(
                              color: isSel ? AppTheme.accent : AppTheme.textSecondary,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(color: isSel ? AppTheme.accent : AppTheme.cardBorder),
                            onSelected: (_) => setState(() => _selectedFilter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Records List
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 52, color: AppTheme.textMuted.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          const Text('No health records found',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('Tap "+ Log Health Record" to record medical history',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: records.length,
                      itemBuilder: (context, i) {
                        final r = records[i];
                        final c = typeColors[r.type] ?? AppTheme.accent;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openAnimal(context, r.sheepId),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.withOpacity(0.25)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.medical_services_rounded, color: c, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Animal Tag & Date
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          FutureBuilder<Animal?>(
                                            future: _db.getAnimalById(r.sheepId),
                                            builder: (ctx, snap) {
                                              final a = snap.data;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryLight,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  a != null
                                                      ? '${a.tagNumber}${a.name.isNotEmpty ? " • ${a.name}" : ""}'
                                                      : 'Animal ID: ${r.sheepId.substring(0, 6)}',
                                                  style: const TextStyle(
                                                    color: AppTheme.accent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            DateFormat('d MMM yyyy').format(r.date),
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        r.description,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (r.medicine != null || r.dosage != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(
                                            'Med: ${r.medicine ?? "-"}${r.dosage != null ? " (${r.dosage} ${r.dosageUnit ?? ""})" : ""}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                          ),
                                        ),
                                      if (r.nextDueDate != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.event_repeat_rounded, size: 12, color: AppTheme.accent),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Next: ${DateFormat('d MMM yyyy').format(r.nextDueDate!)}',
                                                style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                                  color: AppTheme.cardBg,
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(children: [
                                        Icon(Icons.visibility_rounded, color: AppTheme.accent, size: 18),
                                        SizedBox(width: 10),
                                        Text('View Animal', style: TextStyle(color: AppTheme.textPrimary)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_rounded, color: AppTheme.accentBlue, size: 18),
                                        SizedBox(width: 10),
                                        Text('Edit Record', style: TextStyle(color: AppTheme.textPrimary)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 18),
                                        SizedBox(width: 10),
                                        Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
                                      ]),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'view') _openAnimal(context, r.sheepId);
                                    if (val == 'edit') _editRecord(context, r);
                                    if (val == 'delete') _deleteRecord(context, r);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOCK HEALTH SUMMARY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HealthSummaryTab extends StatelessWidget {
  const _HealthSummaryTab();

  @override
  Widget build(BuildContext context) {
    final sheep = context.watch<SheepProvider>().allSheep;
    final stats = [
      _HealthStat('Total Animals', sheep.length, AppTheme.accent, Icons.pets_rounded),
      _HealthStat('Active', sheep.where((s) => s.status == 'Active').length, AppTheme.accentGreen, Icons.check_circle_rounded),
      _HealthStat('Quarantine', sheep.where((s) => s.status == 'Quarantine').length, AppTheme.accent, Icons.warning_rounded),
      _HealthStat('Deceased', sheep.where((s) => s.status == 'Deceased').length, AppTheme.accentRed, Icons.cancel_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
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
