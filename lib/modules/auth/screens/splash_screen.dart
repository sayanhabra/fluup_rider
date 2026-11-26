import 'dart:async';
import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/shared/helpers/app_permission_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _navTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPermissionHelper.requestInitialPermissions();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    // Navigate to Login after 3 seconds
    _navTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) _onFinishSplash();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onFinishSplash() async {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider).asData?.value;
    if (authState is AuthAuthenticated) {
      final nextStep = authState.user.nextStep;
      final verificationStatus = authState.user.verificationStatus;
      if (nextStep.isUnderReview || verificationStatus.isUnderReview) {
        context.go(AppRoutes.profile);
      } else if (nextStep.isHome) {
        context.go(AppRoutes.dashboard);
      } else if (nextStep.isVerificationSubmission) {
        context.go(AppRoutes.kycVerification);
      } else if (nextStep.isProfileSetup) {
        context.go(AppRoutes.profileSetup);
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: GestureDetector(
        onTap: _onFinishSplash,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE53935), // Primary bright crimson
                Color(0xFFD32F2F), // Core Fluup red
                Color(0xFFB71C1C), // Deep crimson
                Color(0xFF7F0000), // Dark red ground
              ],
              stops: [0.0, 0.35, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ─── 1. Bottom City Skyline Silhouette & Scooter Illustration (Screen 1) ───
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.42,
                child: CustomPaint(
                  painter: _SplashCityAndRiderPainter(),
                ),
              ),

              // ─── 2. Top Center Brand & Partner Badge (Screen 1) ───
              SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 40),
                            // Stylized Wing Symbol (Double wing Fluup F)
                            const _FluupWingSymbol(size: 64),
                            const SizedBox(height: 12),

                            // "Fluup" Wordmark
                            const Text(
                              'Fluup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // "Rider" Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                              ),
                              child: const Text(
                                'Rider',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // "Alcohol Delivery Partner"
                            Text(
                              'Alcohol Delivery Partner',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),

                            // Space out so content sits proudly above city silhouette
                            SizedBox(height: size.height * 0.28),
                          ],
                        ),
                      ),
                    ),
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

// ────────────────────────────────────────────────────────────
// FLUTTER VECTOR WING SYMBOL (Pixel-matched to Fluup double-wing icon)
// ────────────────────────────────────────────────────────────
class _FluupWingSymbol extends StatelessWidget {
  final double size;
  const _FluupWingSymbol({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _WingPainter(),
      ),
    );
  }
}

class _WingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Top wing blade
    final topPath = Path()
      ..moveTo(0, size.height * 0.15)
      ..lineTo(size.width * 0.88, 0)
      ..cubicTo(size.width * 1.0, 0, size.width * 0.95, size.height * 0.35, size.width * 0.82, size.height * 0.35)
      ..lineTo(size.width * 0.36, size.height * 0.35)
      ..lineTo(size.width * 0.26, size.height * 0.52)
      ..lineTo(0, size.height * 0.15)
      ..close();
    canvas.drawPath(topPath, paint);

    // Bottom wing blade
    final bottomPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.60)
      ..lineTo(size.width * 0.72, size.height * 0.48)
      ..cubicTo(size.width * 0.84, size.height * 0.48, size.width * 0.78, size.height * 0.78, size.width * 0.68, size.height * 0.78)
      ..lineTo(size.width * 0.38, size.height * 0.78)
      ..lineTo(size.width * 0.24, size.height * 1.0)
      ..lineTo(size.width * 0.12, size.height * 0.60)
      ..close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────
// SPLASH CITY SKYLINE & SCOOTER RIDER PAINTER (Screen 1)
// ────────────────────────────────────────────────────────────
class _SplashCityAndRiderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Distant Skyline (translucent dark red silhouette)
    final distantPaint = Paint()..color = const Color(0xFF6B0E0E).withValues(alpha: 0.55);
    final distantPath = Path();
    distantPath.moveTo(0, h * 0.7);

    final buildings = [
      0.0, 0.08, 0.45,
      0.08, 0.16, 0.38,
      0.16, 0.23, 0.50,
      0.23, 0.32, 0.40,
      0.32, 0.40, 0.30,
      0.40, 0.49, 0.48,
      0.49, 0.58, 0.35,
      0.58, 0.68, 0.52,
      0.68, 0.78, 0.42,
      0.78, 0.88, 0.36,
      0.88, 1.0, 0.46,
    ];

    for (int i = 0; i < buildings.length; i += 3) {
      final x1 = buildings[i] * w;
      final x2 = buildings[i + 1] * w;
      final yTop = buildings[i + 2] * h;
      distantPath.lineTo(x1, yTop);
      distantPath.lineTo(x2, yTop);
    }
    distantPath.lineTo(w, h * 0.75);
    distantPath.lineTo(w, h);
    distantPath.lineTo(0, h);
    distantPath.close();
    canvas.drawPath(distantPath, distantPaint);

    // 2. Closer Skyline (Dark silhouette with glowing window slits)
    final skylinePaint = Paint()..color = const Color(0xFF4A0000).withValues(alpha: 0.7);
    final skylinePath = Path();
    skylinePath.moveTo(0, h * 0.75);

    final nearBuildings = [
      0.0, 0.12, 0.52,
      0.12, 0.22, 0.46,
      0.22, 0.34, 0.56,
      0.34, 0.46, 0.42,
      0.46, 0.60, 0.60,
      0.60, 0.74, 0.48,
      0.74, 0.86, 0.58,
      0.86, 1.0, 0.50,
    ];

    for (int i = 0; i < nearBuildings.length; i += 3) {
      final x1 = nearBuildings[i] * w;
      final x2 = nearBuildings[i + 1] * w;
      final yTop = nearBuildings[i + 2] * h;
      skylinePath.lineTo(x1, yTop);
      skylinePath.lineTo(x2, yTop);
    }
    skylinePath.lineTo(w, h * 0.8);
    skylinePath.lineTo(w, h);
    skylinePath.lineTo(0, h);
    skylinePath.close();
    canvas.drawPath(skylinePath, skylinePaint);

    // 3. Ground / Road
    final groundPaint = Paint()..color = const Color(0xFF330000);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.84, w, h * 0.16), groundPaint);

    // 4. Scooter & Delivery Rider
    final rx = w * 0.42; // Center-ish rider
    final ry = h * 0.80; // Ground contact level

    _drawRider(canvas, rx, ry);
  }

  void _drawRider(Canvas canvas, double cx, double groundY) {
    final redPaint = Paint()..color = const Color(0xFFE53935);
    final darkRedPaint = Paint()..color = const Color(0xFFB71C1C);
    final blackPaint = Paint()..color = const Color(0xFF1A1A1A);
    final rimPaint = Paint()..color = const Color(0xFFE0E0E0);
    final whitePaint = Paint()..color = Colors.white;

    // Rear Wheel
    final rearWheelCenter = Offset(cx - 52, groundY - 14);
    canvas.drawCircle(rearWheelCenter, 18, blackPaint);
    canvas.drawCircle(rearWheelCenter, 11, rimPaint);
    canvas.drawCircle(rearWheelCenter, 4, blackPaint);

    // Front Wheel
    final frontWheelCenter = Offset(cx + 48, groundY - 14);
    canvas.drawCircle(frontWheelCenter, 18, blackPaint);
    canvas.drawCircle(frontWheelCenter, 11, rimPaint);
    canvas.drawCircle(frontWheelCenter, 4, blackPaint);

    // Scooter Body (Red Moped)
    final scooterBody = Path()
      ..moveTo(cx - 56, groundY - 26)
      ..lineTo(cx - 16, groundY - 26)
      ..lineTo(cx + 8, groundY - 20)
      ..lineTo(cx + 26, groundY - 34)
      ..lineTo(cx + 42, groundY - 38)
      ..lineTo(cx + 48, groundY - 22)
      ..lineTo(cx + 36, groundY - 14)
      ..lineTo(cx - 20, groundY - 14)
      ..lineTo(cx - 52, groundY - 18)
      ..close();
    canvas.drawPath(scooterBody, redPaint);

    // Handlebar & Headlight
    canvas.drawLine(Offset(cx + 26, groundY - 34), Offset(cx + 32, groundY - 60), darkRedPaint..strokeWidth = 4);
    canvas.drawCircle(Offset(cx + 33, groundY - 60), 6, redPaint);
    canvas.drawCircle(Offset(cx + 37, groundY - 60), 3, whitePaint); // Headlamp

    // Delivery Box on Back (Screen 1 has big red box with bottle silhouettes)
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 68, groundY - 78, 38, 44),
      const Radius.circular(6),
    );
    canvas.drawRRect(boxRect, redPaint);

    // Bottle Graphic on Delivery Box
    final bottlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    // Wine bottle 1
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 58, groundY - 62, 6, 18), const Radius.circular(2)), bottlePaint);
    canvas.drawRect(Rect.fromLTWH(cx - 56.5, groundY - 70, 3, 8), bottlePaint);
    // Wine bottle 2
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 48, groundY - 60, 7, 16), const Radius.circular(2)), bottlePaint);
    canvas.drawRect(Rect.fromLTWH(cx - 46, groundY - 67, 3, 7), bottlePaint);

    // Rider Legs & Torso (Red Jacket)
    final riderTorso = Path()
      ..moveTo(cx - 24, groundY - 32)
      ..lineTo(cx - 10, groundY - 74)
      ..lineTo(cx + 8, groundY - 74)
      ..lineTo(cx + 12, groundY - 42)
      ..lineTo(cx + 18, groundY - 24)
      ..lineTo(cx + 8, groundY - 24)
      ..lineTo(cx - 4, groundY - 38)
      ..close();
    canvas.drawPath(riderTorso, redPaint);

    // Arms extending to handlebar
    final armPaint = Paint()
      ..color = darkRedPaint.color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 4, groundY - 66), Offset(cx + 30, groundY - 58), armPaint);

    // Rider Helmet / Head (Screen 1 has red helmet with visor facing right)
    final headCenter = Offset(cx + 3, groundY - 86);
    canvas.drawCircle(headCenter, 14, redPaint);
    // Dark Visor
    final visorPaint = Paint()..color = const Color(0xFF1E293B);
    final visorPath = Path()
      ..moveTo(cx + 6, groundY - 92)
      ..lineTo(cx + 16, groundY - 88)
      ..lineTo(cx + 14, groundY - 80)
      ..lineTo(cx + 5, groundY - 82)
      ..close();
    canvas.drawPath(visorPath, visorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
