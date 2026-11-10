import 'dart:math' as math;
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AuthTopBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  final double? height;
  final bool? showBackButton;
  final VoidCallback? onBack;

  const AuthTopBanner({
    super.key,
    this.title = 'Fluup',
    this.subtitle = 'Your Spirits. \nYour Style. Delivered.',
    this.height,
    this.showBackButton,
    this.onBack,
  });

  @override
  State<AuthTopBanner> createState() => _AuthTopBannerState();
}

class _AuthTopBannerState extends State<AuthTopBanner>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _entranceController;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<Offset> _carSlide;
  late final Future<LottieComposition> _lottieComposition;

  @override
  void initState() {
    super.initState();
    _lottieComposition = AssetLottie('assets/animation/drive.json').load();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _brandFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _carSlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerHeight =
        widget.height ?? MediaQuery.sizeOf(context).height * 0.25;
    final canShowBack = widget.showBackButton ?? Navigator.of(context).canPop();

    return Container(
      height: bannerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: Brand.headerGradientLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            // Ambient floating bubbles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) =>
                    CustomPaint(painter: _BubblesPainter(_bgController.value)),
              ),
            ),

            // Optional Back Button
            if (canShowBack)
              Positioned(
                left: 8,
                top: 8,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),

            // Text Content
            Positioned(
              left: 24,
              top: canShowBack ? 52 : 40,
              child: FadeTransition(
                opacity: _brandFade,
                child: SlideTransition(
                  position: _brandSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppStyle.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: AppStyle.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Scooter (Entrance from left + Gentle bobbing)
            Positioned(
              right: -10,
              bottom: -10,
              child: SlideTransition(
                position: _carSlide,
                child: AnimatedBuilder(
                  animation: _bgController,
                  builder: (context, child) {
                    final dy =
                        math.sin(_bgController.value * math.pi * 2 * 6) * 2.5;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: FutureBuilder<LottieComposition>(
                        future: _lottieComposition,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Icon(
                              Icons.delivery_dining,
                              size: 100,
                              color: Colors.white,
                            );
                          }
                          if (snapshot.hasData) {
                            return Lottie(
                              composition: snapshot.data,
                              fit: BoxFit.contain,
                              repeat: true,
                              frameRate: FrameRate.composition,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
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

/// Soft drifting bubbles painted over the banner gradient.
class _BubblesPainter extends CustomPainter {
  final double t; // 0..1 looping

  _BubblesPainter(this.t);

  static const _bubbles = <List<double>>[
    // dx, dy, radius, speed, opacity
    [0.12, 0.25, 36, 1, 0.10],
    [0.45, 0.75, 22, 2, 0.12],
    [0.70, 0.20, 48, 1, 0.08],
    [0.90, 0.60, 28, 3, 0.12],
    [0.30, 0.55, 16, 2, 0.14],
    [0.60, 0.45, 12, 3, 0.16],
    [0.05, 0.80, 30, 1, 0.09],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _bubbles.length; i++) {
      final b = _bubbles[i];
      final phase = (t * b[3] + i / _bubbles.length) * math.pi * 2;
      final x = size.width * b[0] + math.sin(phase) * 14;
      final y = size.height * b[1] + math.cos(phase) * 12;
      final paint = Paint()..color = Colors.white.withValues(alpha: b[4]);
      canvas.drawCircle(Offset(x, y), b[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter old) => old.t != t;
}
