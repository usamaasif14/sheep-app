// add_health_record_screen.dart - Form to add health/vaccination records
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/health_model.dart';
import '../providers/sheep_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String? sheepId;
  final String? sheepName;
  final HealthRecord? existingRecord;

  const AddHealthRecordScreen({
    super.key,
    this.sheepId,
    this.sheepName,
    this.existingRecord,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String? _selectedSheepId;
  String _type = 'Vaccination';
  final _descController = TextEditingController();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  String _dosageUnit = 'ml';
  final _vetController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  bool _setReminder = false;
  bool _isSaving = false;

  final List<String> _types = ['Vaccination', 'Treatment', 'Checkup', 'Deworming'];
  final List<String> _dosageUnits = ['ml', 'mg', 'g', 'tablets', 'units'];

  @override
  void initState() {
    super.initState();
    final rec = widget.existingRecord;
    if (rec != null) {
      _selectedSheepId = rec.sheepId;
      _type = rec.type;
      _descController.text = rec.description;
      _medicineController.text = rec.medicine ?? '';
      _dosageController.text = rec.dosage?.toString() ?? '';
      _dosageUnit = rec.dosageUnit ?? 'ml';
      _vetController.text = rec.veterinarian ?? '';
      _costController.text = rec.cost != null ? rec.cost!.toStringAsFixed(0) : '';
      _notesController.text = rec.notes ?? '';
      _date = rec.date;
      _nextDueDate = rec.nextDueDate;
      _setReminder = rec.nextDueDate != null;
    } else {
      _selectedSheepId = widget.sheepId;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _vetController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRecord != null;
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Text(isEditing ? 'Edit Health Record' : 'Add Health Record',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(isEditing ? 'Save' : 'Save',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
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
              // Animal selection
              _buildSectionTitle('Animal *'),
              const SizedBox(height: 8),
              if (widget.sheepId != null && widget.sheepName != null && widget.existingRecord == null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pets_rounded, color: AppTheme.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.sheepName!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Consumer<SheepProvider>(
                  builder: (ctx, provider, _) {
                    final animals = provider.allAnimals;
                    final hasSelected = animals.any((a) => a.id == _selectedSheepId);
                    return DropdownButtonFormField<String>(
                      value: hasSelected ? _selectedSheepId : null,
                      dropdownColor: AppTheme.cardBg,
                      decoration: const InputDecoration(
                        hintText: 'Select Animal',
                        prefixIcon: Icon(Icons.pets_rounded),
                      ),
                      validator: (v) => v == null ? 'Please select an animal' : null,
                      items: animals.map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.tagNumber} - ${a.name.isNotEmpty ? a.name : a.animalType} (${a.gender})',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedSheepId = v),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Type selector
              _buildSectionTitle('Record Type'),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descController,
                label: 'Description *',
                hint: 'e.g., Annual FMD Vaccination',
                icon: Icons.description_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 12),

              // Medicine
              _buildTextField(
                controller: _medicineController,
                label: 'Medicine / Vaccine Name',
                hint: 'e.g., Covexin 8',
                icon: Icons.medication_rounded,
              ),
              const SizedBox(height: 12),

              // Dosage
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _dosageController,
                      label: 'Dosage',
                      hint: '5',
                      icon: Icons.science_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _dosageUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        filled: true,
                        fillColor: AppTheme.primaryLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                      ),
                      dropdownColor: AppTheme.cardBg,
                      items: _dosageUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _dosageUnit = v ?? 'ml'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vet name
              _buildTextField(
                controller: _vetController,
                label: 'Veterinarian',
                hint: 'Dr. Ahmed',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),

              // Cost
              _buildTextField(
                controller: _costController,
                label: 'Cost (Rs)',
                hint: '500',
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Dates
              _buildSectionTitle('Dates'),
              const SizedBox(height: 12),
              _buildDateTile(
                  label: 'Date of Treatment',
                  date: _date,
                  onTap: () async {
                    final d = await _pickDate(_date);
                    if (d != null) setState(() => _date = d);
                  }),
              const SizedBox(height: 12),
              _buildDateTile(
                  label: 'Next Due Date (Optional)',
                  date: _nextDueDate,
                  hint: 'Tap to set reminder',
                  onTap: () async {
                    final d = await _pickDate(_nextDueDate ?? DateTime.now());
                    if (d != null) setState(() => _nextDueDate = d);
                  },
                  onClear: () => setState(() => _nextDueDate = null),
                ),
              if (_nextDueDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_rounded,
                              color: AppTheme.accent, size: 18),
                          SizedBox(width: 10),
                          Text('Set Reminder Notification',
                              style: TextStyle(color: AppTheme.textPrimary)),
                        ],
                      ),
                      Switch(
                        value: _setReminder,
                        onChanged: (v) => setState(() => _setReminder = v),
                        activeColor: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Notes
              _buildSectionTitle('Notes'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Any additional observations...',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.primaryDark))
                      : Text(isEditing ? 'Save Changes' : 'Save Health Record'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final icons = {
      'Vaccination': Icons.vaccines_rounded,
      'Treatment': Icons.healing_rounded,
      'Checkup': Icons.health_and_safety_rounded,
      'Deworming': Icons.bug_report_rounded,
    };
    final colors = {
      'Vaccination': AppTheme.accentBlue,
      'Treatment': AppTheme.accentRed,
      'Checkup': AppTheme.accentGreen,
      'Deworming': AppTheme.accent,
    };

    return Row(
      children: _types.map((t) {
        final isSelected = _type == t;
        final color = colors[t] ?? AppTheme.accent;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: t != _types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppTheme.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icons[t]!, color: isSelected ? color : AppTheme.textMuted, size: 20),
                  const SizedBox(height: 4),
                  Text(t,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? color : AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    String? hint,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Container(
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
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(
                    date != null
                        ? DateFormat('d MMMM yyyy').format(date)
                        : hint ?? 'Not set',
                    style: TextStyle(
                      color: date != null ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (date != null && onClear != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
              onPressed: onClear,
              tooltip: 'Clear',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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

  Future<DateTime?> _pickDate(DateTime initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(data: AppTheme.darkTheme, child: child!),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSheepId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an animal first!'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final isEditing = widget.existingRecord != null;
      final record = HealthRecord(
        id: isEditing ? widget.existingRecord!.id : _uuid.v4(),
        sheepId: _selectedSheepId!,
        type: _type,
        description: _descController.text.trim(),
        medicine: _medicineController.text.trim().isEmpty
            ? null
            : _medicineController.text.trim(),
        dosage: double.tryParse(_dosageController.text),
        dosageUnit: _dosageUnit,
        veterinarian: _vetController.text.trim().isEmpty ? null : _vetController.text.trim(),
        cost: double.tryParse(_costController.text),
        date: _date,
        nextDueDate: _nextDueDate,
        status: isEditing ? widget.existingRecord!.status : 'Completed',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: isEditing ? widget.existingRecord!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await context.read<SheepProvider>().updateHealthRecord(record);
      } else {
        await context.read<SheepProvider>().addHealthRecord(record);
      }

      // Schedule notification if requested
      if (_setReminder && _nextDueDate != null) {
        await NotificationService().scheduleVaccinationReminder(
          id: _uuid.v4().hashCode,
          sheepName: widget.sheepName ?? 'Animal',
          vaccineName: _descController.text.trim(),
          dueDate: _nextDueDate!,
        );
      }

      // Show in-app success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Health Record Updated' : 'Health Record Saved',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('$_type record ${isEditing ? "updated" : "added"} successfully',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
