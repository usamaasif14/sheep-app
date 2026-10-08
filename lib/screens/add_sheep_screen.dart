// add_animal_screen.dart - Add / edit any animal
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/animal_model.dart';
import '../providers/sheep_provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class AddSheepScreen extends StatefulWidget {
  final Animal? sheep; // null = new, non-null = edit

  const AddSheepScreen({super.key, this.sheep});

  @override
  State<AddSheepScreen> createState() => _AddSheepScreenState();
}

class _AddSheepScreenState extends State<AddSheepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _db = DatabaseService();

  // Controllers
  late TextEditingController _tagCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _costCtrl;

  // State
  String _animalType = 'Sheep';
  bool _customAnimalType = false;
  final _customTypeCtrl = TextEditingController();

  String _gender = 'Female';
  String _status = 'Active';
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365));
  String? _photoPath;
  bool _isSaving = false;
  bool _isCustomBreed = false;

  // Saved lists loaded from DB
  List<String> _savedBreeds = [];
  List<String> _savedLocations = [];
  List<AnimalGroup> _groups = [];
  String? _selectedGroupOwner;

  // Parent selection
  String? _motherId;
  String? _fatherId;
  List<Animal> _females = [];
  List<Animal> _males = [];

  static const List<String> _colors = [
    'White', 'Black', 'Brown', 'Grey', 'Mixed', 'Spotted', 'Red', 'Tan'
  ];
  static const List<String> _statuses = [
    'Active', 'Sold', 'Deceased', 'Quarantine'
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.sheep;
    _tagCtrl = TextEditingController(text: a?.tagNumber ?? '');
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _breedCtrl = TextEditingController(text: a?.breed ?? '');
    _weightCtrl = TextEditingController(text: a?.weight != null && a!.weight > 0 ? a.weight.toString() : '');
    _colorCtrl = TextEditingController(text: a?.color ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _locationCtrl = TextEditingController(text: a?.birthLocation ?? '');
    _costCtrl = TextEditingController(text: a?.purchaseCost != null ? a!.purchaseCost.toString() : '');

    if (a != null) {
      _animalType = a.animalType;
      _gender = a.gender;
      _status = a.status;
      _dateOfBirth = a.dateOfBirth;
      _photoPath = a.photoPath;
      _motherId = a.motherId;
      _fatherId = a.fatherId;
      _selectedGroupOwner = a.groupOwner;

      // Custom animal type?
      if (!kDefaultAnimalTypes.contains(a.animalType)) {
        _customAnimalType = true;
        _customTypeCtrl.text = a.animalType;
      }
      // Custom breed?
      _isCustomBreed = a.breed.isNotEmpty;
    }

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final breeds = await _db.getCustomValues('breed_${_animalType.toLowerCase()}');
    final locations = await _db.getCustomValues('location');
    final groups = await _db.getAllGroups();
    final provider = context.read<SheepProvider>();

    setState(() {
      _savedBreeds = breeds;
      _savedLocations = locations;
      _groups = groups;
      _females = provider.activeFemales;
      _males = provider.activeMales;

      // If editing and breed not in saved list — set as custom
      if (widget.sheep != null && widget.sheep!.breed.isNotEmpty &&
          !_savedBreeds.contains(widget.sheep!.breed)) {
        _isCustomBreed = true;
        _breedCtrl.text = widget.sheep!.breed;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_tagCtrl, _nameCtrl, _breedCtrl, _weightCtrl,
        _colorCtrl, _notesCtrl, _locationCtrl, _costCtrl, _customTypeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Text(
          widget.sheep == null ? 'Add Animal' : 'Edit Animal',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)))
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              // ── Animal Type ──
              _buildSectionTitle('Animal Type'),
              const SizedBox(height: 12),
              _buildAnimalTypeSelector(),
              const SizedBox(height: 16),

              // ── Basic Info ──
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildGenderSelector(),
              const SizedBox(height: 12),
              _buildTextField(ctrl: _tagCtrl, label: 'Tag Number *', hint: 'e.g., AN-001',
                  icon: Icons.label_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Tag number required' : null),
              const SizedBox(height: 12),
              _buildTextField(ctrl: _nameCtrl, label: 'Name (Optional)', hint: 'e.g., Bella',
                  icon: Icons.badge_rounded),
              const SizedBox(height: 12),
              _buildBreedField(),
              const SizedBox(height: 12),
              _buildColorField(),
              const SizedBox(height: 16),

              // ── Birth & Weight ──
              _buildSectionTitle('Birth & Weight'),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 12),
              _buildTextField(ctrl: _weightCtrl, label: 'Current Weight (kg)', hint: '45.5',
                  icon: Icons.monitor_weight_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
              const SizedBox(height: 12),
              _buildTextField(ctrl: _costCtrl, label: 'Purchase / Birth Cost (Rs) — Optional',
                  hint: '15000', icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
              const SizedBox(height: 16),

              // ── Location & Group ──
              _buildSectionTitle('Location & Group'),
              const SizedBox(height: 12),
              _buildLocationField(),
              const SizedBox(height: 12),
              _buildGroupField(),
              const SizedBox(height: 16),

              // ── Parents / Offspring ──
              _buildSectionTitle('Parents (Offspring Tracking)'),
              const SizedBox(height: 12),
              _buildParentField(
                  label: 'Mother',
                  icon: Icons.female_rounded,
                  color: const Color(0xFFEC407A),
                  animals: _females,
                  selected: _motherId,
                  onChanged: (v) => setState(() => _motherId = v)),
              const SizedBox(height: 12),
              _buildParentField(
                  label: 'Father',
                  icon: Icons.male_rounded,
                  color: AppTheme.accentBlue,
                  animals: _males,
                  selected: _fatherId,
                  onChanged: (v) => setState(() => _fatherId = v)),
              const SizedBox(height: 16),

              // ── Status ──
              _buildSectionTitle('Status'),
              const SizedBox(height: 12),
              _buildStatusSelector(),
              const SizedBox(height: 16),

              // ── Notes ──
              _buildSectionTitle('Notes'),
              const SizedBox(height: 12),
              _buildTextField(ctrl: _notesCtrl, label: 'Notes', hint: 'Additional info...',
                  icon: Icons.notes_rounded, maxLines: 4),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(widget.sheep == null ? 'Add Animal' : 'Update Animal'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────────────

  Widget _buildAnimalTypeSelector() {
    if (_customAnimalType) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _customTypeCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Animal Type (custom)',
                prefixIcon: Icon(Icons.pets_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _animalType = v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() {
              _customAnimalType = false;
              _animalType = 'Sheep';
              _customTypeCtrl.clear();
            }),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('List'),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...kDefaultAnimalTypes.map((type) {
          if (type == 'Other') return const SizedBox.shrink();
          final isSelected = _animalType == type;
          return GestureDetector(
            onTap: () async {
              setState(() => _animalType = type);
              await _loadDropdownData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent.withOpacity(0.15) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.cardBorder,
                    width: isSelected ? 2 : 1),
              ),
              child: Text(type,
                  style: TextStyle(
                      color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        }),
        // Custom type chip
        GestureDetector(
          onTap: () => setState(() {
            _customAnimalType = true;
            _animalType = '';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _customAnimalType ? AppTheme.accent.withOpacity(0.15) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _customAnimalType ? AppTheme.accent : AppTheme.cardBorder,
                  width: _customAnimalType ? 2 : 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded,
                  size: 14,
                  color: _customAnimalType ? AppTheme.accent : AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('Custom',
                  style: TextStyle(
                      color: _customAnimalType ? AppTheme.accent : AppTheme.textMuted,
                      fontSize: 13)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBreedField() {
    final breedHints = [..._savedBreeds];

    if (_isCustomBreed || breedHints.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _breedCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g., Merino, Sahiwal...',
                prefixIcon: const Icon(Icons.category_rounded, size: 20),
                filled: true,
                fillColor: AppTheme.primaryLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cardBorder)),
              ),
            ),
          ),
          if (breedHints.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: () => setState(() => _isCustomBreed = false),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                child: const Text('List', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: breedHints.contains(_breedCtrl.text) ? _breedCtrl.text : null,
      decoration: InputDecoration(
        labelText: 'Breed',
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        filled: true,
        fillColor: AppTheme.primaryLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder)),
      ),
      dropdownColor: AppTheme.cardBg,
      items: [
        ...breedHints.map((b) => DropdownMenuItem(
            value: b, child: Text(b, style: const TextStyle(color: AppTheme.textPrimary)))),
        const DropdownMenuItem(
            value: '__custom__',
            child: Text('+ Type custom breed', style: TextStyle(color: AppTheme.accent))),
      ],
      onChanged: (v) {
        if (v == '__custom__') {
          setState(() {
            _isCustomBreed = true;
            _breedCtrl.clear();
          });
        } else {
          _breedCtrl.text = v ?? '';
        }
      },
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Birth / Farm Location (Optional)',
            hintText: 'e.g., North Barn, Field A',
            prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
            filled: true,
            fillColor: AppTheme.primaryLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder)),
          ),
        ),
        if (_savedLocations.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _savedLocations.map((loc) => GestureDetector(
                onTap: () => setState(() => _locationCtrl.text = loc),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Text(loc,
                      style: const TextStyle(color: AppTheme.accent, fontSize: 11)),
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupField() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedGroupOwner,
            decoration: InputDecoration(
              labelText: 'Group / Owner (Optional)',
              prefixIcon: const Icon(Icons.group_rounded, size: 20),
              filled: true,
              fillColor: AppTheme.primaryLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder)),
            ),
            dropdownColor: AppTheme.cardBg,
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text('None', style: TextStyle(color: AppTheme.textMuted))),
              ..._groups.map((g) => DropdownMenuItem(
                  value: g.name,
                  child: Text(g.name,
                      style: const TextStyle(color: AppTheme.textPrimary)))),
            ],
            onChanged: (v) => setState(() => _selectedGroupOwner = v),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_rounded, color: AppTheme.accent),
          tooltip: 'Add new group',
          onPressed: _addGroupDialog,
        ),
      ],
    );
  }

  Widget _buildParentField({
    required String label,
    required IconData icon,
    required Color color,
    required List<Animal> animals,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: animals.any((a) => a.id == selected) ? selected : null,
      decoration: InputDecoration(
        labelText: '$label (Optional)',
        prefixIcon: Icon(icon, size: 20, color: color),
        filled: true,
        fillColor: AppTheme.primaryLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder)),
      ),
      dropdownColor: AppTheme.cardBg,
      items: [
        const DropdownMenuItem(
            value: null,
            child: Text('None', style: TextStyle(color: AppTheme.textMuted))),
        ...animals.map((a) => DropdownMenuItem(
            value: a.id,
            child: Text(
                '${a.tagNumber}${a.name.isNotEmpty ? " - ${a.name}" : ""} (${a.animalType})',
                style: const TextStyle(color: AppTheme.textPrimary)))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildColorField() {
    return DropdownButtonFormField<String>(
      value: _colors.contains(_colorCtrl.text) ? _colorCtrl.text : null,
      decoration: InputDecoration(
        labelText: 'Color',
        prefixIcon: const Icon(Icons.color_lens_rounded, size: 20),
        filled: true,
        fillColor: AppTheme.primaryLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder)),
      ),
      dropdownColor: AppTheme.cardBg,
      items: _colors.map((c) => DropdownMenuItem(
          value: c, child: Text(c, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
      onChanged: (v) => _colorCtrl.text = v ?? '',
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Female', 'Male'].map((g) {
        final isSelected = _gender == g;
        final color = g == 'Female' ? const Color(0xFFEC407A) : AppTheme.accentBlue;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: g == 'Female' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? color : AppTheme.cardBorder,
                    width: isSelected ? 2 : 1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(g == 'Female' ? Icons.female_rounded : Icons.male_rounded,
                    color: isSelected ? color : AppTheme.textMuted, size: 20),
                const SizedBox(width: 8),
                Text(g,
                    style: TextStyle(
                        color: isSelected ? color : AppTheme.textMuted,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 15)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Date of Birth',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(DateFormat('d MMMM yyyy').format(_dateOfBirth),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            ]),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final colors = {
      'Active': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuses.map((s) {
        final isSelected = _status == s;
        final color = colors[s]!;
        return GestureDetector(
          onTap: () => setState(() => _status = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isSelected ? color : AppTheme.cardBorder,
                  width: isSelected ? 2 : 1),
            ),
            child: Text(s,
                style: TextStyle(
                    color: isSelected ? color : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
              color: AppTheme.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder, width: 2)),
          child: _photoPath != null
              ? ClipOval(child: Image.file(File(_photoPath!), fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_rounded, color: AppTheme.accent, size: 32),
                  const SizedBox(height: 4),
                  const Text('Add Photo',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ]),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _photoPath = img.path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: AppTheme.darkTheme, child: child!),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _addGroupDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Add Group / Owner',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
              hintText: 'e.g., Muhammad Ali, Barn 2'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await _db.insertGroup(AnimalGroup(
                  id: const Uuid().v4(),
                  name: name,
                  createdAt: DateTime.now(),
                ));
                await _loadDropdownData();
                setState(() => _selectedGroupOwner = name);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final effectiveType = _customAnimalType ? _customTypeCtrl.text.trim() : _animalType;
    if (effectiveType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an animal type'),
            backgroundColor: AppTheme.accentRed));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final breed = _breedCtrl.text.trim();
      final location = _locationCtrl.text.trim();

      // Save custom breed and location for future
      if (breed.isNotEmpty) {
        await _db.saveCustomValue('breed_${effectiveType.toLowerCase()}', breed);
      }
      if (location.isNotEmpty) {
        await _db.saveCustomValue('location', location);
      }
      // Save custom animal type
      if (_customAnimalType && effectiveType.isNotEmpty) {
        await _db.saveCustomValue('animal_type', effectiveType);
      }

      final provider = context.read<SheepProvider>();
      final now = DateTime.now();

      final animal = Animal(
        id: widget.sheep?.id ?? _uuid.v4(),
        tagNumber: _tagCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        animalType: effectiveType,
        breed: breed,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        weight: double.tryParse(_weightCtrl.text) ?? 0.0,
        color: _colorCtrl.text.trim(),
        status: _status,
        purchaseCost: double.tryParse(_costCtrl.text),
        birthLocation: location.isEmpty ? null : location,
        groupOwner: _selectedGroupOwner,
        motherId: _motherId,
        fatherId: _fatherId,
        photoPath: _photoPath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        dateAdded: widget.sheep?.dateAdded ?? now,
        lastUpdated: now,
      );

      if (widget.sheep == null) {
        await provider.addSheep(animal);
      } else {
        await provider.updateSheep(animal);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
