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
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
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
                  ? ClipOval(
                      child: Image.file(File(sheep.photoPath!),
                          width: 58, height: 58, fit: BoxFit.cover))
                  : Icon(Icons.pets_rounded, color: genderColor, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Text(sheep.tagNumber,
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                // Animal type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(sheep.animalType,
                      style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 4),
                Icon(isFemale ? Icons.female_rounded : Icons.male_rounded,
                    color: genderColor, size: 16),
                const Spacer(),
                _statusPill(sheep.status),
              ]),
              const SizedBox(height: 5),
              Text(
                sheep.name.isNotEmpty ? sheep.name : '(No name)',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text(sheep.breed.isNotEmpty ? sheep.breed : 'Unknown breed',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const Text(' • ',
                    style: TextStyle(color: AppTheme.textMuted)),
                Text(sheep.ageDisplay,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                if (sheep.weight > 0) ...[
                  const Text(' • ',
                      style: TextStyle(color: AppTheme.textMuted)),
                  Text('${sheep.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted, size: 20),
        ]),
      ),
    );
  }

  Widget _statusPill(String status) {
    final colors = {
      'Active': AppTheme.accentGreen,
      'Sold': AppTheme.accentBlue,
      'Deceased': AppTheme.accentRed,
      'Quarantine': AppTheme.accent,
    };
    final color = colors[status] ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
