import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
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
    this.onNotificationsTap,
    this.hasUnreadNotifications = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onLanguageToggle;
  final String languageLabel;
  final VoidCallback? onNotificationsTap;
  final bool hasUnreadNotifications;

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
          onTap: onNotificationsTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.comingSoon),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          hasUnread: hasUnreadNotifications,
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
    this.hasUnreadNotifications = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNotificationsTap;
  final bool hasUnreadNotifications;

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
          _NotificationBell(onTap: onNotificationsTap, hasUnread: hasUnreadNotifications),
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
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
  const _NotificationBell({
    required this.onTap,
    this.hasUnread = false,
  });

  final VoidCallback onTap;
  final bool hasUnread;

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
          if (hasUnread)
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
    final subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: subColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: subColor,
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
    final primary = Theme.of(context).colorScheme.primary;
    final border = Theme.of(context).colorScheme.outlineVariant;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: active ? primary : onSurfaceVariant),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      backgroundColor: active ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
      side: BorderSide(
        color: active ? primary : border,
      ),
      labelStyle: TextStyle(
        color: active ? Theme.of(context).colorScheme.onPrimaryContainer : onSurface,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0x08000000)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'photo-${post.id}',
                child: PhotoPreview(
                  photoUrl: post.photoUrl,
                  category: post.category,
                  size: 100,
                  iconSize: 42,
                ),
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
                          child: Hero(
                            tag: 'title-${post.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                itemPostTitle(post, strings),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
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
                  HapticFeedback.lightImpact();
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
    final subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: subColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: subColor,
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

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 20, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 140, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
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

class FadeInSlide extends StatefulWidget {
  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// User Illustrated Avatar Presets
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.icon,
    required this.gradient,
    required this.emoji,
  });

  final String id;
  final IconData icon;
  final LinearGradient gradient;
  final String emoji;
}

final List<AvatarPreset> avatarPresets = [
  const AvatarPreset(
    id: 'avatar_student',
    icon: Icons.school_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFE8F1FF), Color(0xFF3578F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🎓',
  ),
  const AvatarPreset(
    id: 'avatar_tech',
    icon: Icons.terminal_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFE2F8FA), Color(0xFF087889)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '💻',
  ),
  const AvatarPreset(
    id: 'avatar_security',
    icon: Icons.shield_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFFFF1F2), Color(0xFFE11D48)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🛡️',
  ),
  const AvatarPreset(
    id: 'avatar_guide',
    icon: Icons.explore_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFFFC97C), Color(0xFF9A5B10)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🧭',
  ),
];

AvatarPreset? _presetForUserId(String userId) {
  final normalized = userId.toLowerCase();
  if (normalized.contains('staff') || normalized.contains('security')) {
    return avatarPresets[2]; // Security
  }
  if (normalized.contains('student-18') || normalized.contains('student-22') || normalized.contains('tech')) {
    return avatarPresets[1]; // Tech Scholar
  }
  if (normalized.contains('student')) {
    return avatarPresets[0]; // Student Explorer
  }
  if (normalized.contains('admin') || normalized.contains('housing') || normalized.contains('front')) {
    return avatarPresets[3]; // Campus Guide
  }
  return null;
}

class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    this.size = 44,
  });

  final String userId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? avatarSource;
    String name = '';

    if (userId == 'current-user') {
      avatarSource = ref.watch(profileAvatarProvider);
      name = ref.watch(profileNameProvider);
      if (name.isEmpty) {
        name = AppStrings.of(context).demoUserName;
      }
    } else {
      name = userId.replaceAll(RegExp(r'[_-]+'), ' ').trim();
      final preset = _presetForUserId(userId);
      if (preset != null) {
        avatarSource = preset.id;
      }
    }

    // Determine initials
    final initials = name.isEmpty
        ? '?'
        : name
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    // 1. If it's a preset avatar
    if (avatarSource != null && avatarSource.startsWith('avatar_')) {
      final preset = avatarPresets.firstWhere(
        (p) => p.id == avatarSource,
        orElse: () => avatarPresets[0],
      );

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: preset.gradient,
          border: Border.all(
            color: Colors.white,
            width: size > 60 ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: preset.gradient.colors.last.withValues(alpha: 0.25),
              blurRadius: size * 0.16,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: Icon(
          preset.icon,
          color: Colors.white,
          size: size * 0.46,
        ),
      );
    }

    // 2. If it's a photo (data URI base64)
    final bytes = avatarSource != null ? decodePhotoBytes(avatarSource) : null;
    if (bytes != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: size > 60 ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: size * 0.16,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 3. Fallback: Initials on premium gradient background
    final fallbackGradient = LinearGradient(
      colors: [
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: fallbackGradient,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: size > 60 ? 2 : 1.2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// Confetti Micro-Animation Overlay Widget
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.duration = const Duration(seconds: 4)});

  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();

    final random = math.Random();
    for (var i = 0; i < 45; i++) {
      _particles.add(
        _ConfettiParticle(
          color: _confettiColors[random.nextInt(_confettiColors.length)],
          x: 0.1 + random.nextDouble() * 0.8, // avoid tight edges
          y: -random.nextDouble() * 0.3,
          size: 6.0 + random.nextDouble() * 9.0,
          speedY: 150.0 + random.nextDouble() * 150.0,
          speedX: -30.0 + random.nextDouble() * 60.0,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: -4.0 + random.nextDouble() * 8.0,
          driftFreq: 0.6 + random.nextDouble() * 1.4,
          driftAmp: 12.0 + random.nextDouble() * 18.0,
          shape: _ConfettiShape.values[random.nextInt(_ConfettiShape.values.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

enum _ConfettiShape { circle, square, triangle }

class _ConfettiParticle {
  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.driftFreq,
    required this.driftAmp,
    required this.shape,
  });

  final Color color;
  double x;
  double y;
  final double size;
  final double speedY;
  final double speedX;
  double rotation;
  final double rotationSpeed;
  final double driftFreq;
  final double driftAmp;
  final _ConfettiShape shape;
}

final List<Color> _confettiColors = [
  const Color(0xFF3B82F6), // Blue
  const Color(0xFF10B981), // Green
  const Color(0xFFF59E0B), // Gold
  const Color(0xFFEF4444), // Crimson
  const Color(0xFFEC4899), // Pink
  const Color(0xFF8B5CF6), // Purple
  const Color(0xFF06B6D4), // Cyan
];

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = p.y * size.height + (p.speedY * progress);
      final drift = math.sin(progress * p.driftFreq * math.pi * 2) * p.driftAmp;
      final currentX = p.x * size.width + (p.speedX * progress) + drift;

      if (currentY > size.height + p.size || currentY < -50 || currentX < -50 || currentX > size.width + 50) {
        continue;
      }

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.6,
      );

      switch (p.shape) {
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ConfettiShape.square:
          canvas.drawRect(rect, paint);
          break;
        case _ConfettiShape.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
