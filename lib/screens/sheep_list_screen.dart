// sheep_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/sheep_provider.dart';
import '../models/animal_model.dart';
import '../utils/app_theme.dart';
import '../widgets/sheep_card.dart';
import 'sheep_detail_screen.dart';
import 'add_sheep_screen.dart';

class SheepListScreen extends StatefulWidget {
  const SheepListScreen({super.key});
  @override
  State<SheepListScreen> createState() => _SheepListScreenState();
}

class _SheepListScreenState extends State<SheepListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedGender = 'All';
  bool _isGridView = false;

  final _statusOptions = ['All', 'Active', 'Sold', 'Deceased', 'Quarantine'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SheepProvider>().setStatusFilter('All');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SheepProvider>();
    final animals = provider.allAnimals;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            title: const Text('My Animals',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22)),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.pets_rounded, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 4),
                  Text('${provider.activeCount} Active',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ]),
              ),
            ],
          ),

          // Search + filters
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: provider.setSearch,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by tag, name, type or breed...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                            })
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    ..._statusOptions.map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s),
                            selected: _selectedStatus == s,
                            onSelected: (_) {
                              setState(() => _selectedStatus = s);
                              provider.setStatusFilter(s);
                            },
                            selectedColor: AppTheme.accent.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _selectedStatus == s
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: _selectedStatus == s
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        )),
                    Container(
                        width: 1,
                        height: 24,
                        color: AppTheme.cardBorder,
                        margin: const EdgeInsets.only(right: 8)),
                    ...[
                      ('Female', Icons.female_rounded, const Color(0xFFEC407A)),
                      ('Male', Icons.male_rounded, AppTheme.accentBlue),
                    ].map((g) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(g.$2,
                                  size: 14,
                                  color: _selectedGender == g.$1
                                      ? g.$3
                                      : AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(g.$1),
                            ]),
                            selected: _selectedGender == g.$1,
                            onSelected: (val) {
                              setState(() =>
                                  _selectedGender = val ? g.$1 : 'All');
                              provider.setGenderFilter(val ? g.$1 : 'All');
                            },
                          ),
                        )),
                  ]),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${animals.length} animal${animals.length != 1 ? 's' : ''} found',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isGridView = !_isGridView),
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),

          // List / grid
          if (provider.isLoading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent)))
          else if (animals.isEmpty)
            SliverFillRemaining(child: _emptyState(context))
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _gridCard(ctx, animals[i], i),
                  childCount: animals.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(animals[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.accentRed.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: AppTheme.accentRed, size: 26),
                      ),
                      confirmDismiss: (_) =>
                          _confirmDelete(context, animals[i]),
                      onDismissed: (_) =>
                          provider.deleteSheep(animals[i].id),
                      child: SheepCard(
                        sheep: animals[i],
                        onTap: () => _openDetail(context, animals[i]),
                      ).animate(delay: Duration(milliseconds: i * 50))
                          .fadeIn()
                          .slideX(begin: -0.1),
                    ),
                  ),
                  childCount: animals.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddSheepScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Animal',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Widget _gridCard(BuildContext context, Animal a, int i) {
    final color =
        a.gender == 'Female' ? const Color(0xFFEC407A) : AppTheme.accentBlue;
    return GestureDetector(
      onTap: () => _openDetail(context, a),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(Icons.pets_rounded, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(a.tagNumber,
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(a.name.isEmpty ? '—' : a.name,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12)),
          Text(a.animalType,
              style: const TextStyle(
                  color: AppTheme.accent, fontSize: 10),
              overflow: TextOverflow.ellipsis),
          Text(a.breed.isEmpty ? '—' : a.breed,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(a.ageDisplay,
                style: const TextStyle(
                    color: AppTheme.accentGreen, fontSize: 10)),
          ),
        ]),
      ).animate(delay: Duration(milliseconds: i * 60))
          .fadeIn()
          .scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets_rounded, size: 64, color: AppTheme.accent),
        ),
        const SizedBox(height: 20),
        const Text('No animals found',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Add your first animal to get started',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddSheepScreen())),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add First Animal'),
        ),
      ]),
    );
  }

  void _openDetail(BuildContext context, Animal a) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => SheepDetailScreen(sheep: a)));
  }

  Future<bool> _confirmDelete(BuildContext context, Animal a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Remove Animal',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            'Remove ${a.name.isEmpty ? a.tagNumber : "${a.name} (${a.tagNumber})"}?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed),
              child: const Text('Delete')),
        ],
      ),
    );
    return ok == true;
  }
}
