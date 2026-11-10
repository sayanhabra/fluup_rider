import 'dart:async';
import 'dart:math' as math;
import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthStep { mobile, name, otp }

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ───
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _mobileFocus = FocusNode();
  final _nameFocus = FocusNode();

  // ─── Local Flow State ───
  _AuthStep _step = _AuthStep.mobile;
  String? _phone;
  String? _challengeToken;
  int _cooldownSeconds = 0;
  int _cooldownTotal = 1;
  Timer? _cooldownTimer;
  String? _errorText;

  // ─── Animation Controllers ───
  late AnimationController _animationController; // entrance
  late AnimationController _bgController; // looping ambient motion
  late AnimationController _shakeController; // error shake
  late Animation<Offset> _bannerSlide;
  late Animation<Offset> _carSlide;
  late Animation<Offset> _formSlide;
  late Animation<double> _brandFade;
  late Animation<Offset> _brandSlide;

  // ─── Lottie Future (Loads once) ───
  late Future<LottieComposition> _lottieComposition;

  // ─── Validation ───
  bool get _isMobileValid => _mobileController.text.trim().length == 10;
  bool get _isNameValid => _nameController.text.trim().length >= 2;
  bool get _isOtpComplete => _otpControllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();

    // Load Lottie once into memory to prevent loop blinking
    _lottieComposition = AssetLottie('assets/animation/drive.json').load();

    // Setup Screen Entrance Animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bannerSlide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _brandFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _brandSlide = Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    _carSlide = Tween<Offset>(begin: const Offset(-1.4, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.25, 0.85, curve: Curves.easeOutBack),
          ),
        );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _mobileFocus.dispose();
    _nameFocus.dispose();
    _cooldownTimer?.cancel();
    _animationController.dispose();
    _bgController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Cooldown Timer ───
  void _startCooldown(int seconds) {
    _cooldownSeconds = seconds;
    _cooldownTotal = seconds <= 0 ? 1 : seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  // ─── Error handling ───
  void _clearError() {
    if (_errorText != null) setState(() => _errorText = null);
  }

  void _setError(String message) {
    setState(() => _errorText = message);
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _focusAfterBuild(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  Future<void> _checkPhone() async {
    if (!_isMobileValid) return;
    _clearError();
    FocusScope.of(context).unfocus();

    final phone = '+91${_mobileController.text.trim()}';
    final notifier = ref.read(authNotifierProvider.notifier);
    final String phoneNumber = phone;

    await notifier.checkPhone(phoneNumber);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider).asData?.value;

    if (authState is AuthPhoneChecked) {
      _phone = phoneNumber;
      setState(() => _step = _AuthStep.name);
      _focusAfterBuild(_nameFocus);
    } else if (authState is AuthOtpSent) {
      _phone = phoneNumber;
      _challengeToken = authState.challengeToken;
      _startCooldown(authState.cooldownSeconds);
      setState(() => _step = _AuthStep.otp);
      _focusAfterBuild(_otpFocusNodes[0]);
    } else if (authState is AuthUnauthenticated) {
      _setError(authState.message ?? 'Something went wrong');
    } else {
      _setError('Unexpected error occurred');
    }
  }

  Future<void> _sendOtp() async {
    if (_phone == null) return;
    _clearError();
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);

    await notifier.sendOtp(phone: _phone!, name: name);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider).asData?.value;

    if (authState is AuthOtpSent) {
      _challengeToken = authState.challengeToken;
      _startCooldown(authState.cooldownSeconds);
      final wasOtp = _step == _AuthStep.otp;
      setState(() => _step = _AuthStep.otp);
      if (!wasOtp) _focusAfterBuild(_otpFocusNodes[0]);
    } else if (authState is AuthUnauthenticated) {
      _setError(authState.message ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _challengeToken == null || _phone == null) return;
    _clearError();
    FocusScope.of(context).unfocus();

    final otp = _otpControllers.map((c) => c.text).join();
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : null;

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.verifyOtp(
      phone: _phone!,
      code: otp,
      name: name,
      challengeToken: _challengeToken!,
    );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider).asData?.value;
    if (authState is AuthUnauthenticated) {
      _setError(authState.message ?? 'Invalid OTP code');
    }
  }

  void _goBack() {
    _clearError();
    if (_step == _AuthStep.otp) {
      setState(() {
        _step = _AuthStep.mobile;
        _challengeToken = null;
        for (final c in _otpControllers) {
          c.clear();
        }
      });
    } else if (_step == _AuthStep.name) {
      setState(() => _step = _AuthStep.mobile);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? ColorName.primaryBackgroundDark : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  // 1. TOP BANNER (Slides from Top)
                  SlideTransition(
                    position: _bannerSlide,
                    child: _buildBanner(context),
                  ),

                  // 3. BOTTOM FORM SECTION (Slides from Bottom)
                  SlideTransition(
                    position: _formSlide,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height * 0.65,
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStepIndicator(),
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final t = _shakeController.value;
                                final dx =
                                    math.sin(t * math.pi * 6) * 8 * (1 - t);
                                return Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: child,
                                );
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    ...previous,
                                    ?current,
                                  ],
                                ),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.08, 0),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    ),
                                child: _buildCurrentSection(),
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
            if (isLoading)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, v, child) =>
                      Opacity(opacity: v, child: child),
                  child: DashboardLoadingScreen(
                    message: _step == _AuthStep.otp
                        ? 'Verifying OTP... 🔐'
                        : 'Please wait... ⏳',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Banner ───
  Widget _buildBanner(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.25,
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

            // Text Content
            Positioned(
              left: 24,
              top: 40,
              child: FadeTransition(
                opacity: _brandFade,
                child: SlideTransition(
                  position: _brandSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fluup',
                        style: AppStyle.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Spirits. \nYour Style. Delivered.',
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

            // 2. ANIMATED CAR (Slides from Left, then gently bobs)
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
                            return _lottieError(
                              context,
                              snapshot.error!,
                              snapshot.stackTrace,
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
                          // Keep invisible while loading so it doesn't flash
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

  // ─── Step progress indicator ───
  Widget _buildStepIndicator() {
    final current = _step.index;
    return Row(
      children: List.generate(3, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          height: 5,
          width: i == current ? 32 : 12,
          decoration: BoxDecoration(
            color: active
                ? Brand.red
                : (context.isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentSection() {
    return switch (_step) {
      _AuthStep.name => _buildNameSection(),
      _AuthStep.otp => _buildOtpSection(),
      _AuthStep.mobile => _buildMobileSection(),
    };
  }

  Widget _buildHeader({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyle.heading2.copyWith(
            color: Theme.of(context).textTheme.displayLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppStyle.bodyMedium.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorText() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: _errorText == null
            ? const SizedBox(key: ValueKey('no-error'), width: double.infinity)
            : Padding(
                key: ValueKey(_errorText),
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: AppStyle.bodySmall.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  InputDecoration _premiumInputDecoration({
    required String hint,
    IconData? icon,
    String? prefixText,
  }) {
    final isDark = context.isDarkMode;
    final fillColor = isDark ? Colors.grey.shade900 : const Color(0xFFF5F6F5);

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
      prefixText: prefixText,
      prefixStyle: AppStyle.titleMedium.copyWith(color: Colors.black87),
      hintStyle: AppStyle.bodyMedium.copyWith(color: Colors.grey.shade400),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Brand.red, width: 1.5),
      ),
    );
  }

  Widget _buildMobileSection() {
    return Column(
      key: const ValueKey('mobile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stagger(
          index: 0,
          child: _buildHeader(
            title: 'Welcome to Fluup',
            subtitle: 'Log In or Sign Up to continue',
          ),
        ),
        const SizedBox(height: 32),
        _Stagger(
          index: 1,
          child: Text(
            'Enter mobile number',
            style: AppStyle.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Stagger(
          index: 2,
          child: Row(
            children: [
              Container(
                height: 60,
                width: 70,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.grey.shade900
                      : const Color(0xFFF5F6F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlowField(
                  focusNode: _mobileFocus,
                  radius: 12,
                  child: TextField(
                    controller: _mobileController,
                    focusNode: _mobileFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) {
                      _clearError();
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: _premiumInputDecoration(
                      hint: 'Mobile number',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _Stagger(
          index: 3,
          child: _buildPremiumButton(
            text: 'Continue',
            isEnabled: _isMobileValid,
            onPressed: _checkPhone,
          ),
        ),
        _buildErrorText(),
      ],
    );
  }

  Widget _buildNameSection() {
    return Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stagger(
          index: 0,
          child: _buildHeader(
            title: 'Welcome!',
            subtitle: 'Tell us your name to get started',
          ),
        ),
        const SizedBox(height: 32),
        _Stagger(
          index: 1,
          child: Text(
            'Full Name',
            style: AppStyle.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Stagger(
          index: 2,
          child: _GlowField(
            focusNode: _nameFocus,
            radius: 16,
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                _clearError();
                setState(() {});
              },
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: _premiumInputDecoration(
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _Stagger(
          index: 3,
          child: _buildPremiumButton(
            text: 'Continue',
            isEnabled: _isNameValid,
            onPressed: _sendOtp,
          ),
        ),
        _buildErrorText(),
        const SizedBox(height: 16),
        _Stagger(
          index: 4,
          child: Center(
            child: TextButton(
              onPressed: _goBack,
              child: Text(
                'Change mobile number',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stagger(
          index: 0,
          child: _buildHeader(
            title: 'Verify OTP',
            subtitle: 'Enter the 6-digit code sent to your phone',
          ),
        ),
        const SizedBox(height: 16),
        _Stagger(
          index: 1,
          child: Row(
            children: [
              Text(
                'Sent to ',
                style: AppStyle.bodySmall.copyWith(color: Colors.grey.shade500),
              ),
              Text(
                _phone ?? '',
                style: AppStyle.titleSmall.copyWith(
                  color: Theme.of(context).textTheme.titleSmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => _Stagger(
              index: 2,
              extraDelayMs: index * 50,
              child: _buildOtpField(index),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _Stagger(
          index: 4,
          child: _buildPremiumButton(
            text: 'Verify OTP',
            isEnabled: _isOtpComplete,
            onPressed: _verifyOtp,
          ),
        ),
        _buildErrorText(),
        const SizedBox(height: 24),
        _Stagger(index: 5, child: Center(child: _buildResendButton())),
        const SizedBox(height: 16),
        _Stagger(
          index: 6,
          child: Center(
            child: TextButton(
              onPressed: _goBack,
              child: Text(
                'Change mobile number',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton({
    required String text,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return _PremiumButton(
      text: text,
      isEnabled: isEnabled,
      onPressed: onPressed,
    );
  }

  Widget _buildOtpField(int index) {
    final focusNode = _otpFocusNodes[index];
    final controller = _otpControllers[index];

    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final filled = controller.text.isNotEmpty;
        final isDark = context.isDarkMode;

        return AnimatedScale(
          scale: focused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: Brand.red.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppStyle.heading4.copyWith(
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) {
                _clearError();
                if (value.isNotEmpty) HapticFeedback.selectionClick();
                if (value.isNotEmpty && index < 5) {
                  _otpFocusNodes[index + 1].requestFocus();
                }
                if (value.isEmpty && index > 0) {
                  _otpFocusNodes[index - 1].requestFocus();
                }
                setState(() {});
              },
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: filled
                    ? Brand.red.withValues(alpha: isDark ? 0.18 : 0.08)
                    : (isDark ? Colors.grey.shade900 : const Color(0xFFF5F6F5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: filled
                      ? BorderSide(
                          color: Brand.red.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Brand.red, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: _cooldownSeconds > 0
          ? Row(
              key: const ValueKey('cooldown'),
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (_cooldownSeconds / _cooldownTotal).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 2.5,
                      color: Brand.red,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Didn't receive the code? Resend OTP in ${_cooldownSeconds}s",
                  style: AppStyle.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            )
          : TextButton(
              key: const ValueKey('resend'),
              onPressed: _sendOtp,
              child: const Text(
                "Didn't receive the code? Resend OTP in",
                style: TextStyle(color: Brand.red, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}

// ============================================================
// Helper widgets
// ============================================================

/// Fades + slides its child in after a small staggered delay.
class _Stagger extends StatefulWidget {
  final int index;
  final int extraDelayMs;
  final Widget child;

  const _Stagger({
    required this.index,
    required this.child,
    this.extraDelayMs = 0,
  });

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(curved);

    _timer = Timer(
      Duration(milliseconds: 80 + widget.index * 70 + widget.extraDelayMs),
      () {
        if (mounted) _c.forward();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Soft red glow around an input while it has focus.
class _GlowField extends StatelessWidget {
  final FocusNode focusNode;
  final double radius;
  final Widget child;

  const _GlowField({
    required this.focusNode,
    required this.child,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: Brand.red.withValues(alpha: 0.08),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: child,
      ),
    );
  }
}

/// Gradient button with press-scale, animated enable/disable and arrow.
class _PremiumButton extends StatefulWidget {
  final String text;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _PremiumButton({
    required this.text,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;

    return AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? Brand.headerGradientLight
              : const LinearGradient(colors: [Colors.grey, Colors.grey]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Brand.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed();
                  }
                : null,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: enabled
                        ? const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
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

// Extracted error builder for Lottie
Widget _lottieError(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  return const Icon(Icons.delivery_dining, size: 100, color: Colors.white);
}
