import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../l10n/app_strings.dart';

const collegeLogoAssetPath = 'assets/images/college_logo.png';
const useCollegeLogoAsset = true;

class PhotoStyle {
  const PhotoStyle({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
}

PhotoStyle photoStyleForCategory(ItemCategory category) {
  return switch (category) {
    ItemCategory.electronics => const PhotoStyle(
      icon: Icons.headphones_rounded,
      colors: [Color(0xFFE8F1FF), Color(0xFF3578F6)],
    ),
    ItemCategory.keys => const PhotoStyle(
      icon: Icons.key_rounded,
      colors: [Color(0xFFFFC97C), Color(0xFF9A5B10)],
    ),
    ItemCategory.bag => const PhotoStyle(
      icon: Icons.backpack_rounded,
      colors: [Color(0xFF45678F), Color(0xFF0A2758)],
    ),
    ItemCategory.cards => const PhotoStyle(
      icon: Icons.credit_card_rounded,
      colors: [Color(0xFFFDA4AF), Color(0xFFE11D48)],
    ),
    ItemCategory.other => const PhotoStyle(
      icon: Icons.inventory_2_rounded,
      colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
    ),
  };
}

Uint8List? decodePhotoBytes(String photoUrl) {
  if (!photoUrl.startsWith('data:')) return null;
  final commaIndex = photoUrl.indexOf(',');
  if (commaIndex < 0) return null;
  try {
    return base64Decode(photoUrl.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

String dataUriFromBytes(Uint8List bytes) {
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

TextStyle? sectionLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w900,
    color: const Color(0xFF0A2758),
  );
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onLanguageToggle,
    required this.languageLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onLanguageToggle;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _CampusCrest(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0A2758),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF1C63E8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1C63E8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationBell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.comingSoon),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

class PremiumHomeHeader extends StatelessWidget {
  const PremiumHomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onNotificationsTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _CampusCrest(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0A2758),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF1C63E8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1C63E8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NotificationBell(onTap: onNotificationsTap),
        ],
      ),
    );
  }
}

class _CampusCrest extends StatelessWidget {
  const _CampusCrest({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A2758),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: useCollegeLogoAsset
            ? const CollegeLogoAsset(
                fallback: CustomPaint(painter: _CampusCrestPainter()),
              )
            : const CustomPaint(painter: _CampusCrestPainter()),
      ),
    );
  }
}

class CollegeLogoAsset extends StatelessWidget {
  const CollegeLogoAsset({super.key, required this.fallback});

  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ByteData?>(
      future: _tryLoadCollegeLogoAsset(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return fallback;
        final bytes = snapshot.data!.buffer.asUint8List();
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}

Future<ByteData?> _tryLoadCollegeLogoAsset() async {
  try {
    return await rootBundle.load(collegeLogoAssetPath);
  } catch (_) {
    return null;
  }
}

class _CampusCrestPainter extends CustomPainter {
  const _CampusCrestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final navy = Paint()..color = const Color(0xFF0A2758);
    final navyStroke = Paint()
      ..color = const Color(0xFF102A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final goldStroke = Paint()
      ..color = const Color(0xFFE2B84C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final white = Paint()..color = Colors.white;

    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..lineTo(size.width * 0.68, size.height * 0.27)
      ..lineTo(size.width * 0.65, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.78,
        size.width * 0.35,
        size.height * 0.55,
      )
      ..lineTo(size.width * 0.32, size.height * 0.27)
      ..close();
    canvas.drawPath(shield, navy);

    final book = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 1),
        width: size.width * 0.26,
        height: size.height * 0.14,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(book, white);
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.06),
      Offset(center.dx, center.dy + size.height * 0.08),
      navyStroke,
    );
    canvas.drawLine(
      Offset(center.dx - size.width * 0.09, center.dy - size.height * 0.015),
      Offset(center.dx + size.width * 0.09, center.dy - size.height * 0.015),
      navyStroke,
    );

    _drawLaurel(canvas, size, left: true, paint: goldStroke);
    _drawLaurel(canvas, size, left: false, paint: goldStroke);
  }

  void _drawLaurel(
    Canvas canvas,
    Size size, {
    required bool left,
    required Paint paint,
  }) {
    final startX = left ? size.width * 0.24 : size.width * 0.76;
    final direction = left ? -1.0 : 1.0;
    final path = Path()..moveTo(startX, size.height * 0.3);
    for (var i = 0; i < 5; i++) {
      final t = i / 4;
      final x = startX + direction * size.width * 0.06 * t;
      final y = size.height * (0.32 + t * 0.32);
      path.quadraticBezierTo(
        x + direction * size.width * 0.03,
        y - size.height * 0.02,
        x,
        y,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: AppStrings.of(context).notifications,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF0A2758),
            size: 26,
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF1C63E8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class PremiumHomeSearchBar extends StatelessWidget {
  const PremiumHomeSearchBar({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.filters,
    required this.strings,
    required this.onFilterTap,
    required this.onReset,
  });

  final FilterState filters;
  final AppStrings strings;
  final VoidCallback onFilterTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final status = filters.status == null
        ? strings.allStatuses
        : statusLabel(filters.status!, strings);
    final category = filters.category == null
        ? strings.category
        : categoryLabel(filters.category!, strings);
    final date = dateFilterLabel(filters.dateFilter, strings);
    final location = filters.locationLabel == null
        ? strings.location
        : campusLocationLabelText(filters.locationLabel!, strings);

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChipButton(
            icon: Icons.adjust_rounded,
            label: status,
            active: filters.status != null,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            icon: Icons.tune_rounded,
            label: category,
            active: filters.category != null,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            icon: Icons.date_range_rounded,
            label: date,
            active: filters.dateFilter != DateFilter.any,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            icon: Icons.place_outlined,
            label: location,
            active: filters.locationLabel != null,
            onTap: onFilterTap,
          ),
          if (filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            FilterChipButton(
              icon: Icons.restart_alt_rounded,
              label: strings.reset,
              active: true,
              onTap: onReset,
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      backgroundColor: active ? const Color(0xFFDBEAFE) : Colors.white,
      side: BorderSide(
        color: active ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        color: active ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class ItemPostCard extends StatelessWidget {
  const ItemPostCard({
    super.key,
    required this.post,
    required this.strings,
    required this.onTap,
    required this.onFavorite,
  });

  final ItemPost post;
  final AppStrings strings;
  final VoidCallback onTap;
  final Future<void> Function() onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${itemPostTitle(post, strings)}, ${statusLabel(post.status, strings)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPreview(
                photoUrl: post.photoUrl,
                category: post.category,
                size: 100,
                iconSize: 42,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            itemPostTitle(post, strings),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(status: post.status, strings: strings),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InfoLine(
                      icon: categoryIcon(post.category),
                      label: categoryLabel(post.category, strings),
                    ),
                    const SizedBox(height: 5),
                    InfoLine(
                      icon: Icons.location_on_outlined,
                      label: campusLocationLabel(post.location, strings),
                    ),
                    const SizedBox(height: 5),
                    InfoLine(
                      icon: Icons.schedule_rounded,
                      label: relativeTime(post.dateTime, strings),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  unawaited(onFavorite());
                },
                tooltip: strings.favorites,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    post.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(post.isFavorite),
                    color: post.isFavorite
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.strings});

  final PostStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PostStatus.lost => const Color(0xFFDC2626),
      PostStatus.found => const Color(0xFF15803D),
      PostStatus.recovered => const Color(0xFF1D4ED8),
    };
    final background = switch (status) {
      PostStatus.lost => const Color(0xFFFEE2E2),
      PostStatus.found => const Color(0xFFDCFCE7),
      PostStatus.recovered => const Color(0xFFDBEAFE),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel(status, strings),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({
    super.key,
    required this.photoUrl,
    required this.category,
    this.size = 120,
    this.iconSize = 50,
    this.borderRadius = 12,
  });

  final String photoUrl;
  final ItemCategory category;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _ItemPhotoFrame(
      photoUrl: photoUrl,
      style: photoStyleForCategory(category),
      size: size,
      iconSize: iconSize,
      borderRadius: borderRadius,
    );
  }
}

class LargePhotoPreview extends StatelessWidget {
  const LargePhotoPreview({
    super.key,
    required this.photoUrl,
    required this.category,
  });

  final String photoUrl;
  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    return _ItemPhotoFrame(
      photoUrl: photoUrl,
      style: photoStyleForCategory(category),
      size: double.infinity,
      iconSize: 104,
      borderRadius: 22,
      showLargeIcon: true,
    );
  }
}

class _ItemPhotoFrame extends StatelessWidget {
  const _ItemPhotoFrame({
    required this.photoUrl,
    required this.style,
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    this.showLargeIcon = false,
  });

  final String photoUrl;
  final PhotoStyle style;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showLargeIcon;

  @override
  Widget build(BuildContext context) {
    final bytes = decodePhotoBytes(photoUrl);
    if (bytes != null) {
      final image = Image.memory(bytes, fit: BoxFit.cover);
      if (size.isInfinite) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox.expand(child: image),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size.isInfinite ? null : size,
      height: size.isInfinite ? null : size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -12,
            child: Icon(
              style.icon,
              size: iconSize * (showLargeIcon ? 1.9 : 1.8),
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Center(
            child: Icon(style.icon, size: iconSize, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class MiniMapPreview extends StatelessWidget {
  const MiniMapPreview({super.key, required this.location});

  final CampusLocation location;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: CampusMapPainter())),
            Align(
              alignment: const Alignment(0.16, -0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0796A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(blurRadius: 12, color: Color(0x18000000)),
                      ],
                    ),
                    child: Text(
                      campusLocationLabel(location, AppStrings.of(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minorRoadPaint = Paint()
      ..color = const Color(0xFFD9E2EA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final lawnPaint = Paint()..color = const Color(0xFFCFE8C9);
    final buildingPaint = Paint()..color = const Color(0xFFE7D8BA);

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.64, size.height * 0.08, 86, 62),
      lawnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.62, 104, 46),
        const Radius.circular(8),
      ),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.58, 84, 44),
        const Radius.circular(8),
      ),
      buildingPaint,
    );

    final path = Path()
      ..moveTo(-20, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.2,
        size.width * 0.58,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.7,
        size.width + 20,
        size.height * 0.64,
      );
    canvas.drawPath(path, roadPaint);

    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.42, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.38),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.18),
      minorRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.resetLabel,
    required this.onReset,
  });

  final String title;
  final String subtitle;
  final String resetLabel;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE2F8FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                size: 52,
                color: Color(0xFF0796A8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(resetLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedSheet extends StatelessWidget {
  const RoundedSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD5DEEA),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
