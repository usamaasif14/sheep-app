// add_sheep_screen.dart - Form to add/edit a sheep
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/sheep_model.dart';
import '../providers/sheep_provider.dart';
import '../utils/app_theme.dart';

class AddSheepScreen extends StatefulWidget {
  final Sheep? sheep; // null = adding new, non-null = editing

  const AddSheepScreen({super.key, this.sheep});

  @override
  State<AddSheepScreen> createState() => _AddSheepScreenState();
}

class _AddSheepScreenState extends State<AddSheepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  late TextEditingController _tagController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  late TextEditingController _colorController;
  late TextEditingController _notesController;

  String _gender = 'Female';
  String _status = 'Active';
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365));
  String? _photoPath;
  bool _isSaving = false;

  final List<String> _breeds = [
    'Merino', 'Suffolk', 'Dorper', 'Corriedale', 'Romney',
    'Texel', 'Border Leicester', 'Jacob', 'Rambouillet', 'Other (type manually)',
  ];
  bool _isCustomBreed = false;

  final List<String> _colors = ['White', 'Black', 'Brown', 'Grey', 'Mixed', 'Spotted'];

  @override
  void initState() {
    super.initState();
    final s = widget.sheep;
    _tagController = TextEditingController(text: s?.tagNumber ?? '');
    _nameController = TextEditingController(text: s?.name ?? '');
    _breedController = TextEditingController(text: s?.breed ?? '');
    _weightController = TextEditingController(text: s?.weight.toString() ?? '');
    _colorController = TextEditingController(text: s?.color ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    if (s != null) {
      _gender = s.gender;
      _status = s.status;
      _dateOfBirth = s.dateOfBirth;
      _photoPath = s.photoPath;
      // If editing and breed is not in standard list, switch to manual mode
      if (s.breed.isNotEmpty && !_breeds.contains(s.breed)) {
        _isCustomBreed = true;
      }
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _notesController.dispose();
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
          widget.sheep == null ? 'Add New Sheep' : 'Edit Sheep',
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent)),
            )
          else
            TextButton(
              onPressed: _saveSheep,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              // Gender selector
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildGenderSelector(),
              const SizedBox(height: 16),

              // Tag Number
              _buildTextField(
                controller: _tagController,
                label: 'Tag Number *',
                hint: 'e.g., SH-001',
                icon: Icons.label_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Tag number is required' : null,
              ),
              const SizedBox(height: 12),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Name (Optional)',
                hint: 'e.g., Bella',
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),

              // Breed
              _buildBreedField(),
              const SizedBox(height: 12),

              // Color
              _buildColorField(),
              const SizedBox(height: 16),

              // Date of Birth
              _buildSectionTitle('Birth & Weight'),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 12),

              // Weight
              _buildTextField(
                controller: _weightController,
                label: 'Current Weight (kg)',
                hint: 'e.g., 45.5',
                icon: Icons.monitor_weight_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
              const SizedBox(height: 16),

              // Status
              _buildSectionTitle('Status'),
              const SizedBox(height: 12),
              _buildStatusSelector(),
              const SizedBox(height: 16),

              // Notes
              _buildSectionTitle('Additional Notes'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any additional information...',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSheep,
                  child: Text(widget.sheep == null ? 'Add Sheep to Flock' : 'Update Sheep'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.cardBorder, width: 2),
          ),
          child: _photoPath != null
              ? ClipOval(child: Image.file(File(_photoPath!), fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_rounded,
                        color: AppTheme.accent, size: 32),
                    const SizedBox(height: 4),
                    const Text('Add Photo',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
        ),
      ),
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
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    g == 'Female' ? Icons.female_rounded : Icons.male_rounded,
                    color: isSelected ? color : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    g,
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreedField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCustomBreed)
          DropdownButtonFormField<String>(
            value: _breeds.contains(_breedController.text) ? _breedController.text : null,
            decoration: InputDecoration(
              labelText: 'Breed',
              prefixIcon: const Icon(Icons.category_rounded, size: 20),
              filled: true,
              fillColor: AppTheme.primaryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
            ),
            dropdownColor: AppTheme.cardBg,
            items: _breeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) {
              if (v == 'Other (type manually)') {
                setState(() {
                  _isCustomBreed = true;
                  _breedController.clear();
                });
              } else {
                _breedController.text = v ?? '';
              }
            },
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _breedController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Breed (custom)',
                    hintText: 'e.g., Awassi, Karakul...',
                    prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    filled: true,
                    fillColor: AppTheme.primaryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => setState(() {
                    _isCustomBreed = false;
                    _breedController.clear();
                  }),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                  child: const Text('List', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildColorField() {
    return DropdownButtonFormField<String>(
      value: _colors.contains(_colorController.text) ? _colorController.text : null,
      decoration: InputDecoration(
        labelText: 'Color',
        prefixIcon: const Icon(Icons.color_lens_rounded, size: 20),
        filled: true,
        fillColor: AppTheme.primaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      dropdownColor: AppTheme.cardBg,
      items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => _colorController.text = v ?? '',
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
            const Icon(Icons.calendar_today_rounded,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date of Birth',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  DateFormat('d MMMM yyyy').format(_dateOfBirth),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = {
      'Active': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.entries.map((e) {
        final isSelected = _status == e.key;
        return GestureDetector(
          onTap: () => setState(() => _status = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? e.value.withOpacity(0.15) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? e.value : AppTheme.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              e.key,
              style: TextStyle(
                color: isSelected ? e.value : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.accent,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _photoPath = image.path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme,
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _saveSheep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<SheepProvider>();
      final now = DateTime.now();

      if (widget.sheep == null) {
        final sheep = Sheep(
          id: _uuid.v4(),
          tagNumber: _tagController.text.trim(),
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          weight: double.tryParse(_weightController.text) ?? 0.0,
          color: _colorController.text.trim(),
          status: _status,
          photoPath: _photoPath,
          notes: _notesController.text.trim(),
          dateAdded: now,
          lastUpdated: now,
        );
        await provider.addSheep(sheep);
      } else {
        final updated = widget.sheep!.copyWith(
          tagNumber: _tagController.text.trim(),
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          weight: double.tryParse(_weightController.text) ?? 0.0,
          color: _colorController.text.trim(),
          status: _status,
          photoPath: _photoPath,
          notes: _notesController.text.trim(),
          lastUpdated: now,
        );
        await provider.updateSheep(updated);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
