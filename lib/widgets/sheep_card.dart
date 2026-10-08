// sheep_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../utils/app_theme.dart';

class SheepCard extends StatelessWidget {
  final Animal sheep;
  final VoidCallback onTap;
  const SheepCard({super.key, required this.sheep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFemale = sheep.gender == 'Female';
    final genderColor = isFemale ? const Color(0xFFEC407A) : AppTheme.accentBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor(sheep.status), width: sheep.status == 'Pregnant' ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Avatar
          Hero(
            tag: 'animal-${sheep.id}',
            child: Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: genderColor.withOpacity(0.15),
                border: Border.all(color: genderColor.withOpacity(0.4), width: 1.5),
              ),
              child: sheep.photoPath != null && File(sheep.photoPath!).existsSync()
                  ? ClipOval(child: Image.file(File(sheep.photoPath!), width: 58, height: 58, fit: BoxFit.cover))
                  : Icon(Icons.pets_rounded, color: genderColor, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row: tag + type + gender + status
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Text(sheep.tagNumber, style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(5)),
                  child: Text(sheep.animalType, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ),
                const SizedBox(width: 4),
                Icon(isFemale ? Icons.female_rounded : Icons.male_rounded, color: genderColor, size: 15),
                const Spacer(),
                _statusPill(sheep.status),
              ]),
              const SizedBox(height: 4),
              // Name + life stage
              Row(children: [
                Expanded(
                  child: Text(
                    sheep.name.isNotEmpty ? sheep.name : '(No name)',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(sheep.stage, style: const TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 3),
              // Breed · age · weight
              Row(children: [
                Text(sheep.breed.isNotEmpty ? sheep.breed : 'Unknown', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const Text(' · ', style: TextStyle(color: AppTheme.textMuted)),
                Text(sheep.ageDisplay, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (sheep.weight > 0) ...[
                  const Text(' · ', style: TextStyle(color: AppTheme.textMuted)),
                  Text('${sheep.weight.toStringAsFixed(1)} kg', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ]),
              // Mother name (if set)
              if (sheep.motherName != null && sheep.motherName!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.female_rounded, size: 11, color: Color(0xFFEC407A)),
                  const SizedBox(width: 3),
                  Text('Mother: ${sheep.motherName}', style: const TextStyle(color: Color(0xFFEC407A), fontSize: 11)),
                ]),
              ],
              // Partnership badge
              if (sheep.ownershipType == 'Partnership' && sheep.partnerName != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.handshake_rounded, size: 11, color: AppTheme.accentBlue),
                  const SizedBox(width: 3),
                  Text('Partner: ${sheep.partnerName}', style: const TextStyle(color: AppTheme.accentBlue, fontSize: 11)),
                ]),
              ],
            ]),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        ]),
      ),
    );
  }

  Color _borderColor(String status) {
    switch (status) {
      case 'Pregnant': return const Color(0xFFEC407A).withOpacity(0.5);
      case 'Gave Birth': return AppTheme.accentGreen.withOpacity(0.5);
      case 'Quarantine': return AppTheme.accent.withOpacity(0.5);
      default: return AppTheme.cardBorder;
    }
  }

  Widget _statusPill(String status) {
    final colors = {
      'Active': AppTheme.accentGreen,
      'Pregnant': const Color(0xFFEC407A),
      'Gave Birth': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    final icons = {
      'Pregnant': '🤰',
      'Gave Birth': '🐣',
    };
    final c = colors[status] ?? AppTheme.textMuted;
    final emoji = icons[status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        emoji != null ? '$emoji $status' : status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
