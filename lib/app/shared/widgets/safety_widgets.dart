import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../l10n/app_strings.dart';

class SafetyGuidanceCard extends StatelessWidget {
  const SafetyGuidanceCard({
    super.key,
    required this.category,
    required this.strings,
  });

  final ItemCategory category;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Light warning yellow
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.safetyGuideTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.safetyGuideSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.proveOwnershipTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 6, left: 6),
                child: Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
              ),
              Expanded(
                child: Text(
                  strings.safetyPromptForCategory(category),
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            strings.verifiedPickupTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          ...strings.verifiedLocations.map((loc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFFD97706)),
                    ),
                    Expanded(
                      child: Text(
                        loc,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.privateInfoWarning,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
