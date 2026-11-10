import 'package:adm_rider/core/config/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// LOADING SCREEN — logo gently zooms in / out
// ============================================================================
class DashboardLoadingScreen extends StatefulWidget {
  const DashboardLoadingScreen({
    super.key,
    this.message = 'Loading...',
    this.logo,
    this.logoAsset = 'assets/png/flupp.png',
  });

  /// Status line shown under the logo. Changing it cross-fades the text
  /// without restarting the logo animation.
  final String message;

  /// Pass your own logo widget (e.g. `Assets.images.logo.image()`).
  /// If null, [logoAsset] is used.
  final Widget? logo;

  /// Asset path used when [logo] is null. Must be declared in pubspec.yaml.
  final String logoAsset;

  @override
  State<DashboardLoadingScreen> createState() => _DashboardLoadingScreenState();
}

class _DashboardLoadingScreenState extends State<DashboardLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.93,
    end: 1.07,
  ).animate(_curve);

  late final Animation<double> _ringScale = Tween<double>(
    begin: 0.9,
    end: 1.2,
  ).animate(_curve);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    final fallback = Icon(
      Icons.local_shipping_rounded,
      size: 52,
      color: Brand.red,
    );
    return widget.logo ??
        Image.asset(
          widget.logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final bgColors = dark
        ? const [Brand.darkBg, Brand.darkBg]
        : const [Brand.topBlush, Colors.white];
    final coreColor = dark ? Brand.darkSurface : Colors.white;
    final textColor = dark ? Brand.muted : Brand.subtext;
    final trackColor = dark
        ? Brand.darkBorder
        : Brand.redBorder.withValues(alpha: 0.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgColors,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Logo with soft pulsing glow ---
              SizedBox(
                height: 220,
                width: 220,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Transform.scale(
                          scale: _ringScale.value,
                          child: Container(
                            height: 170,
                            width: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Brand.red.withValues(
                                alpha: dark ? 0.06 : 0.05,
                              ),
                            ),
                          ),
                        ),
                        // Inner glow ring (moves opposite)
                        Transform.scale(
                          scale: 2.1 - _ringScale.value,
                          child: Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Brand.red.withValues(
                                alpha: dark ? 0.10 : 0.08,
                              ),
                            ),
                          ),
                        ),
                        // Logo card
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            height: 118,
                            width: 118,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: coreColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dark
                                    ? Brand.darkBorder
                                    : Brand.redBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Brand.red.withValues(alpha: 0.22),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _buildLogo(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // --- Message ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.message,
                  key: ValueKey(widget.message),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Slim progress bar ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 120,
                  height: 4,
                  child: LinearProgressIndicator(
                    color: Brand.red,
                    backgroundColor: trackColor,
                  ),
                ),
              ),

              // Optical balance — nudges the logo slightly above centre
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
