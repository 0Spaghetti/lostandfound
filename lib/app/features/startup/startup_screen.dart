import 'package:flutter/material.dart';

import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF2FF)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _SplashCampusBackdrop()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _CampusEmblem(size: 124),
                    const SizedBox(height: 22),
                    Text(
                      strings.splashTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF102A5C),
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.splashSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF5C7194),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: Center(
                child: SizedBox(
                  width: 110,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    backgroundColor: Color(0xFFD8E4F8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusEmblem extends StatelessWidget {
  const _CampusEmblem({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A2758),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: const CollegeLogoAsset(
          fallback: CustomPaint(painter: _EmblemPainter()),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final shieldPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.14)
      ..lineTo(size.width * 0.72, size.height * 0.24)
      ..lineTo(size.width * 0.69, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.84,
        size.width * 0.31,
        size.height * 0.56,
      )
      ..lineTo(size.width * 0.28, size.height * 0.24)
      ..close();

    final shieldFill = Paint()..color = const Color(0xFF12326A);
    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF0A2758);

    canvas.drawPath(shieldPath, shieldFill);
    canvas.drawPath(shieldPath, shieldStroke);

    final bookPaint = Paint()..color = Colors.white;
    final spinePaint = Paint()..color = const Color(0xFFD7E4FF);
    final accentPaint = Paint()..color = const Color(0xFF7AA4FF);
    final linePaint = Paint()
      ..color = const Color(0xFF8FB1E8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 2),
        width: size.width * 0.34,
        height: size.height * 0.19,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(bookRect, bookPaint);
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.09),
      Offset(center.dx, center.dy + size.height * 0.1),
      spinePaint,
    );
    canvas.drawLine(
      Offset(center.dx - size.width * 0.13, center.dy - size.height * 0.035),
      Offset(center.dx + size.width * 0.13, center.dy - size.height * 0.035),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - size.width * 0.11, center.dy + size.height * 0.015),
      Offset(center.dx + size.width * 0.11, center.dy + size.height * 0.015),
      linePaint,
    );
    canvas.drawCircle(Offset(center.dx + 1, center.dy + 1), 4, accentPaint);

    final laurelLeft = _laurelPath(size, left: true);
    final laurelRight = _laurelPath(size, left: false);
    final laurelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE2B84C);
    canvas.drawPath(laurelLeft, laurelPaint);
    canvas.drawPath(laurelRight, laurelPaint);
  }

  Path _laurelPath(Size size, {required bool left}) {
    final path = Path();
    final startX = left ? size.width * 0.22 : size.width * 0.78;
    final direction = left ? -1.0 : 1.0;
    path.moveTo(startX, size.height * 0.26);
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      final x = startX + direction * size.width * 0.07 * t;
      final y = size.height * (0.3 + t * 0.32);
      path.quadraticBezierTo(
        x + direction * size.width * 0.02,
        y - size.height * 0.03,
        x,
        y,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashCampusBackdrop extends StatelessWidget {
  const _SplashCampusBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashBackdropPainter());
  }
}

class _SplashBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8C9E6).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final thin = Paint()
      ..color = const Color(0xFFB8C9E6).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.76),
      Offset(size.width * 0.92, size.height * 0.76),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.52,
        size.width * 0.18,
        size.height * 0.18,
      ),
      thin,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.48,
        size.width * 0.14,
        size.height * 0.22,
      ),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.7),
      Offset(size.width * 0.22, size.height * 0.43),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 0.79, size.height * 0.7),
      Offset(size.width * 0.79, size.height * 0.38),
      thin,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.58),
        radius: size.width * 0.18,
      ),
      3.3,
      1.2,
      false,
      thin,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.61),
        radius: size.width * 0.24,
      ),
      3.0,
      1.3,
      false,
      thin,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _complete() {
    widget.onContinue();
  }

  Future<void> _showLocationPermissionSheet(AppStrings strings) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              8,
              22,
              MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF7F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF087889),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.locationPermissionTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0A2758),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.locationPermissionBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF53657E),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _complete();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF1D55D8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(strings.allow),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _complete();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(strings.notNow),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final pages = _pages(strings);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _pageIndex < pages.length - 1
                    ? TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            pages.length - 1,
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF53657E),
                          minimumSize: const Size(0, 40),
                        ),
                        child: Text(
                          strings.skip,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox(height: 40), // Stable alignment height
              ),
              const SizedBox(height: 4),
              Text(
                strings.onboardingWelcomeTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF1D55D8),
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.onboardingWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF53657E),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    return _OnboardingPageView(data: pages[index]);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _PageDots(total: pages.length, activeIndex: _pageIndex),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_pageIndex < pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    _showLocationPermissionSheet(strings);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF1D55D8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    _pageIndex < pages.length - 1 ? strings.next : strings.getStarted,
                    key: ValueKey<int>(_pageIndex < pages.length - 1 ? 0 : 1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _complete,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF1D55D8),
                ),
                child: Text(
                  strings.continueAsGuest,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_OnboardingPageData> _pages(AppStrings strings) {
    return [
      _OnboardingPageData(
        title: strings.onboardingPage1Title,
        subtitle: strings.onboardingPage1Subtitle,
        primaryIcon: Icons.key_rounded,
        primaryColor: const Color(0xFFE2B84C),
        secondaryIcon1: Icons.account_balance_wallet_rounded,
        secondaryColor1: const Color(0xFF2D7DF0),
        secondaryIcon2: Icons.backpack_rounded,
        secondaryColor2: const Color(0xFF15A56E),
      ),
      _OnboardingPageData(
        title: strings.onboardingPage2Title,
        subtitle: strings.onboardingPage2Subtitle,
        primaryIcon: Icons.search_rounded,
        primaryColor: const Color(0xFF2D7DF0),
        secondaryIcon1: Icons.key_rounded,
        secondaryColor1: const Color(0xFFE2B84C),
        secondaryIcon2: Icons.account_balance_wallet_rounded,
        secondaryColor2: const Color(0xFF15A56E),
      ),
      _OnboardingPageData(
        title: strings.onboardingPage3Title,
        subtitle: strings.onboardingPage3Subtitle,
        primaryIcon: Icons.chat_bubble_outline_rounded,
        primaryColor: const Color(0xFF12326A),
        secondaryIcon1: Icons.backpack_rounded,
        secondaryColor1: const Color(0xFF2D7DF0),
        secondaryIcon2: Icons.key_rounded,
        secondaryColor2: const Color(0xFFE2B84C),
      ),
    ];
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.primaryColor,
    required this.secondaryIcon1,
    required this.secondaryColor1,
    required this.secondaryIcon2,
    required this.secondaryColor2,
  });

  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final Color primaryColor;
  final IconData secondaryIcon1;
  final Color secondaryColor1;
  final IconData secondaryIcon2;
  final Color secondaryColor2;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final illustrationHeight = (constraints.maxHeight - 128).clamp(
            118.0,
            320.0,
          );
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OnboardingIllustration(
                      data: data,
                      height: illustrationHeight,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0A2758),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF53657E),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.data, required this.height});

  final _OnboardingPageData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = (height / 320).clamp(0.62, 1.0);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          const Positioned.fill(child: _CampusSceneBackground()),
          Positioned(
            top: 42 * scale,
            left: 22 * scale,
            child: _ItemBadge(
              icon: data.secondaryIcon1,
              color: data.secondaryColor1,
              size: 72 * scale,
              iconSize: 28 * scale,
            ),
          ),
          Positioned(
            top: 58 * scale,
            right: 18 * scale,
            child: _ItemBadge(
              icon: data.secondaryIcon2,
              color: data.secondaryColor2,
              size: 60 * scale,
              iconSize: 28 * scale,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: _ItemBadge(
              icon: data.primaryIcon,
              color: data.primaryColor,
              size: 108 * scale,
              iconSize: 42 * scale,
            ),
          ),
          Positioned(
            bottom: 26 * scale,
            left: 44 * scale,
            right: 44 * scale,
            child: Container(
              height: 18 * scale,
              decoration: BoxDecoration(
                color: const Color(0x0F0A2758),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusSceneBackground extends StatelessWidget {
  const _CampusSceneBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CampusScenePainter());
  }
}

class _CampusScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8FBFF), Color(0xFFF1F6FF)],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      skyPaint,
    );

    final buildingPaint = Paint()..color = const Color(0xFFDDE8F8);
    final buildingAccent = Paint()..color = const Color(0xFFB9CBE4);
    final roadPaint = Paint()
      ..color = const Color(0xFFE5ECF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final treePaint = Paint()..color = const Color(0xFFC9E6D0);
    final treeStem = Paint()
      ..color = const Color(0xFF8EA38F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.34, 110, 120),
        const Radius.circular(20),
      ),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.64, size.height * 0.28, 132, 150),
        const Radius.circular(20),
      ),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.46,
          size.width * 0.64,
          28,
        ),
        const Radius.circular(18),
      ),
      buildingAccent,
    );

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.84),
      Offset(size.width * 0.88, size.height * 0.84),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.72),
      Offset(size.width * 0.38, size.height * 0.56),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.72),
      Offset(size.width * 0.78, size.height * 0.56),
      roadPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      24,
      treePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.18, size.height * 0.34),
      treeStem,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      20,
      treePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.24),
      Offset(size.width * 0.82, size.height * 0.33),
      treeStem,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ItemBadge extends StatelessWidget {
  const _ItemBadge({
    required this.icon,
    required this.color,
    required this.size,
    this.iconSize = 28,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x150A2758),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE7EDF7)),
      ),
      child: Center(
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.total, required this.activeIndex});

  final int total;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: active ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF12326A) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
