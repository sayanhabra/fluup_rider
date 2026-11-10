// modules/auth/screens/auth_status_scaffold.dart

import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:adm_rider/core/shared/widgets/auth_top_banner.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:flutter/material.dart';

class AuthStatusScaffold extends StatelessWidget {
  final Widget child;
  final bool showBanner;
  final String? bannerTitle;
  final String? bannerSubtitle;
  final double? bannerHeight;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final bool isLoading;
  final String? loadingMessage;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const AuthStatusScaffold({
    super.key,
    required this.child,
    this.showBanner = true,
    this.bannerTitle,
    this.bannerSubtitle,
    this.bannerHeight,
    this.showBackButton,
    this.onBack,
    this.isLoading = false,
    this.loadingMessage,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ColorName.primaryBackgroundDark : Colors.white,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  if (showBanner)
                    AuthTopBanner(
                      title: bannerTitle ?? 'Fluup',
                      subtitle: bannerSubtitle ??
                          'Your Spirits. \nYour Style. Delivered.',
                      height: bannerHeight,
                      showBackButton: showBackButton,
                      onBack: onBack,
                    ),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height * 0.70,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppStyle.spaceXLarge,
                      AppStyle.spaceLarge,
                      AppStyle.spaceXLarge,
                      AppStyle.spaceXLarge,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: child,
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
                    message: loadingMessage ?? 'Please wait... ⏳',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
