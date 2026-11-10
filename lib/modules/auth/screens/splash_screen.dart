import 'dart:async';
import 'dart:math' as math;
import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/app_permission_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _horizontalSlide;

  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textScale;
  late final Animation<double> _taglineSpacing;

  // Ambient looping background motion
  late final AnimationController _bgController;

  Timer? _showTextTimer;
  Timer? _hideTextTimer;
  Timer? _sequenceTimer;
  bool _isNavigating = false;

  // Tweak this if the car sits higher/lower in your Lottie file.
  static const double _streakTopFactor = 0.62;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPermissionHelper.requestInitialPermissions();
    });

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 1. Image sliding animation (Total: 4500ms)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _horizontalSlide = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25, // 0ms - 1125ms (Enter)
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 50, // 1125ms - 3375ms (Wait in center)
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25, // 3375ms - 4500ms (Exit)
      ),
    ]).animate(_slideController);

    // 2. Text animation
    _textController = AnimationController(
      vsync: this,
      // 1125ms so it matches the Lottie's exit duration exactly.
      duration: const Duration(milliseconds: 1125),
    );

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _textScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _taglineSpacing = Tween<double>(begin: 3.0, end: 0.2).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // 3. Start the precise sequence
    _startSequence();
  }

  void _startSequence() {
    // Start Lottie sliding
    _slideController.forward();

    // Timer 1: Show text exactly when Lottie hits center (1125ms)
    _showTextTimer = Timer(const Duration(milliseconds: 1125), () {
      if (mounted) _textController.forward();
    });

    // Timer 2: Hide text exactly when Lottie starts exiting (3375ms)
    _hideTextTimer = Timer(const Duration(milliseconds: 3375), () {
      if (mounted) _textController.reverse();
    });

    // Timer 3: Navigate when BOTH are completely done.
    // Lottie ends at 4500ms. Text fade ends at 3375 + 1125 = 4500ms.
    _sequenceTimer = Timer(const Duration(milliseconds: 4600), () {
      if (mounted) _onGetStarted();
    });
  }

  @override
  void dispose() {
    _showTextTimer?.cancel();
    _hideTextTimer?.cancel();
    _sequenceTimer?.cancel();
    _slideController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider).asData?.value;
    if (authState is AuthAuthenticated) {
      final nextStep = authState.user.nextStep;
      if (nextStep.isHome) {
        context.go(AppRoutes.dashboard);
      } else if (nextStep.isVerificationSubmission) {
        context.go(AppRoutes.kycVerification);
      } else if (nextStep.isProfileSetup) {
        context.go(AppRoutes.profileSetup);
      } else if (nextStep.isUnderReview) {
        context.go(AppRoutes.underReview);
      } else if (nextStep.isRejectedRetry) {
        context.go(AppRoutes.kycRetry);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const lottieWidth = 280.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Stack(
        children: [
          // Soft radial glow background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.9,
                  colors: [
                    Brand.red.withValues(alpha: 0.07),
                    const Color(0xFFFDFDFD),
                  ],
                ),
              ),
            ),
          ),

          // Drifting ambient bubbles
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) =>
                    CustomPaint(painter: _BubblesPainter(_bgController.value)),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation (+ speed streaks while moving)
                AnimatedBuilder(
                  animation: _horizontalSlide,
                  builder: (context, child) {
                    final value = _horizontalSlide.value;
                    final offsetX = value * (screenWidth / 2 + lottieWidth / 2);
                    final streakOpacity = (value.abs() * 1.4).clamp(0.0, 1.0);

                    return Transform.translate(
                      offset: Offset(offsetX, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -110,
                            top: lottieWidth * _streakTopFactor,
                            child: Opacity(
                              opacity: streakOpacity,
                              child: const _SpeedStreaks(),
                            ),
                          ),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: SizedBox(
                    width: lottieWidth,
                    height: lottieWidth,
                    child: Lottie.asset(
                      'assets/animation/moving_driver.json',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: _lottieErrorBuilder,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Animated Text
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: ScaleTransition(
                      scale: _textScale,
                      child: Column(
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Brand.red, Brand.danger],
                            ).createShader(bounds),
                            child: const Text(
                              'Fluup',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _taglineSpacing,
                            builder: (context, _) => Text(
                              'Your Spirits. Your Style. Delivered.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Brand.danger,
                                letterSpacing: _taglineSpacing.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom progress bar tied to the splash timeline
          Positioned(
            left: 56,
            right: 56,
            bottom: 56,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, _) {
                  final v = _slideController.value;
                  final fadeIn = (v / 0.12).clamp(0.0, 1.0);
                  final fadeOut = ((1 - v) / 0.1).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: math.min(fadeIn, fadeOut),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Brand.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Brand.red, Brand.danger],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Brand.red.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three fading horizontal lines trailing behind the moving car.
class _SpeedStreaks extends StatelessWidget {
  const _SpeedStreaks();

  Widget _line(double width, double opacity) => Container(
    width: width,
    height: 3,
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        colors: [
          Brand.red.withValues(alpha: 0),
          Brand.red.withValues(alpha: opacity),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_line(90, 0.35), _line(60, 0.25), _line(75, 0.3)],
    );
  }
}

/// Faint drifting circles for a soft, lively backdrop.
class _BubblesPainter extends CustomPainter {
  final double t; // 0..1 looping

  _BubblesPainter(this.t);

  static const _bubbles = <List<double>>[
    // dx, dy, radius, speed, opacity
    [0.15, 0.18, 46, 1, 0.05],
    [0.85, 0.25, 30, 2, 0.06],
    [0.25, 0.78, 38, 1, 0.05],
    [0.80, 0.72, 54, 1, 0.04],
    [0.50, 0.10, 18, 3, 0.07],
    [0.10, 0.50, 22, 2, 0.06],
    [0.92, 0.50, 16, 3, 0.07],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _bubbles.length; i++) {
      final b = _bubbles[i];
      final phase = (t * b[3] + i / _bubbles.length) * math.pi * 2;
      final x = size.width * b[0] + math.sin(phase) * 16;
      final y = size.height * b[1] + math.cos(phase) * 14;
      final paint = Paint()..color = Brand.red.withValues(alpha: b[4]);
      canvas.drawCircle(Offset(x, y), b[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter old) => old.t != t;
}

Widget _lottieErrorBuilder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  return const Icon(Icons.delivery_dining, size: 100, color: Colors.green);
}
