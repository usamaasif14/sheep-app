// sheep_list_screen.dart - Flock management with search and filter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../providers/sheep_provider.dart';
import '../models/sheep_model.dart';
import '../utils/app_theme.dart';
import '../widgets/sheep_card.dart';
import '../widgets/section_header.dart';
import 'sheep_detail_screen.dart';
import 'add_sheep_screen.dart';

class SheepListScreen extends StatefulWidget {
  const SheepListScreen({super.key});

  @override
  State<SheepListScreen> createState() => _SheepListScreenState();
}

class _SheepListScreenState extends State<SheepListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'Active';
  String _selectedGender = 'All';
  bool _isGridView = false;

  final List<String> _statusOptions = ['All', 'Active', 'Sold', 'Deceased', 'Quarantine'];
  final List<String> _genderOptions = ['All', 'Female', 'Male'];

  @override
  void initState() {
    super.initState();
    context.read<SheepProvider>().setStatusFilter(_selectedStatus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SheepProvider>();
    final sheep = provider.allSheep;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, provider),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search bar
                _buildSearchBar(provider),
                const SizedBox(height: 12),
                // Filter chips
                _buildFilterChips(provider),
                const SizedBox(height: 16),
                // Counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sheep.length} sheep found',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                      icon: Icon(
                        _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          // Sheep list/grid
          if (provider.isLoading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent)))
          else if (sheep.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context))
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildSheepGridCard(context, sheep[i], i),
                  childCount: sheep.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SheepCard(
                      sheep: sheep[i],
                      onTap: () => _openDetail(context, sheep[i]),
                    ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: -0.1),
                  ),
                  childCount: sheep.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheep(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Sheep', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, SheepProvider provider) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      title: const Text('My Flock',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets_rounded, color: AppTheme.accent, size: 14),
              const SizedBox(width: 4),
              Text(
                '${provider.activeCount} Active',
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(SheepProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearch,
      decoration: InputDecoration(
        hintText: 'Search by tag, name or breed...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearch('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChips(SheepProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._statusOptions.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: _selectedStatus == s,
                  onSelected: (val) {
                    setState(() => _selectedStatus = s);
                    provider.setStatusFilter(s);
                  },
                  selectedColor: AppTheme.accent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedStatus == s ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: _selectedStatus == s ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              )),
          Container(width: 1, height: 24, color: AppTheme.cardBorder, margin: const EdgeInsets.only(right: 8)),
          ..._genderOptions.skip(1).map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        g == 'Female' ? Icons.female_rounded : Icons.male_rounded,
                        size: 14,
                        color: _selectedGender == g
                            ? (g == 'Female' ? const Color(0xFFEC407A) : AppTheme.accentBlue)
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(g),
                    ],
                  ),
                  selected: _selectedGender == g,
                  onSelected: (val) {
                    setState(() => _selectedGender = val ? g : 'All');
                    provider.setGenderFilter(val ? g : 'All');
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSheepGridCard(BuildContext context, Sheep sheep, int index) {
    return GestureDetector(
      onTap: () => _openDetail(context, sheep),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (sheep.gender == 'Female'
                    ? const Color(0xFFEC407A)
                    : AppTheme.accentBlue)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 28,
                color: sheep.gender == 'Female'
                    ? const Color(0xFFEC407A)
                    : AppTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(sheep.tagNumber,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(sheep.name.isEmpty ? '—' : sheep.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            Text(sheep.breed,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sheep.ageDisplay,
                style: const TextStyle(color: AppTheme.accentGreen, fontSize: 10),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, size: 64, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('No sheep found',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add your first sheep to get started!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddSheep(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Sheep'),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Sheep sheep) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SheepDetailScreen(sheep: sheep)),
    );
  }

  void _openAddSheep(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSheepScreen()),
    );
  }
}
