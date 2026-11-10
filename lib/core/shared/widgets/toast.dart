import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';

enum AppToastType { success, error, warning, info, plain }

class AppToast {
  AppToast._();

  // ============================================================
  // SUCCESS TOAST
  // ============================================================

  static CancelFunc success({
    required String title,
    String? message,
    Widget? icon,
    Duration? duration,
  }) {
    return _show(
      title: title,
      message: message,
      type: AppToastType.success,
      icon: icon,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // ============================================================
  // ERROR TOAST
  // ============================================================

  static CancelFunc error({
    required String title,
    String? message,
    Widget? icon,
    Duration? duration,
  }) {
    return _show(
      title: title,
      message: message,
      type: AppToastType.error,
      icon: icon,
      duration: duration ?? Duration(seconds: kDebugMode ? 10 : 5),
    );
  }

  // ============================================================
  // WARNING TOAST
  // ============================================================

  static CancelFunc warning({
    required String title,
    String? message,
    Widget? icon,
    Duration? duration,
  }) {
    return _show(
      title: title,
      message: message,
      type: AppToastType.warning,
      icon: icon,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  // ============================================================
  // INFO TOAST
  // ============================================================

  static CancelFunc info({
    required String title,
    String? message,
    Widget? icon,
    Duration? duration,
  }) {
    return _show(
      title: title,
      message: message,
      type: AppToastType.info,
      icon: icon,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // ============================================================
  // PLAIN TOAST
  // ============================================================

  static CancelFunc plain({
    required String title,
    String? message,
    Widget? icon,
    Duration? duration,
  }) {
    return _show(
      title: title,
      message: message,
      type: AppToastType.plain,
      icon: icon,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // ============================================================
  // COMMON TOAST BUILDER
  // ============================================================

  static CancelFunc _show({
    required String title,
    String? message,
    required AppToastType type,
    Widget? icon,
    required Duration duration,
  }) {
    // Avoid showing empty toast.
    if (title.trim().isEmpty) {
      return () {};
    }

    return BotToast.showCustomNotification(
      duration: duration,

      toastBuilder: (cancelFunc) {
        return Builder(
          builder: (context) {
            final config = _getConfig(type, context);
            return SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: config.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --------------------------------------------
                    // ICON
                    // --------------------------------------------
                    icon ??
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: config.iconColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            config.icon,
                            color: config.iconColor,
                            size: 21,
                          ),
                        ),

                    const SizedBox(width: 12),

                    // --------------------------------------------
                    // CONTENT
                    // --------------------------------------------
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: config.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if (message != null && message.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),

                            Text(
                              message,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: config.textColor.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // --------------------------------------------
                    // CLOSE BUTTON
                    // --------------------------------------------
                    InkWell(
                      onTap: cancelFunc,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: config.textColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TOAST CONFIG
  // ============================================================

  static _ToastConfig _getConfig(AppToastType type, [BuildContext? context]) {
    final isDark =
        context != null && Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case AppToastType.success:
        return _ToastConfig(
          backgroundColor: isDark
              ? const Color(0xFF1B2F22)
              : ColorName.toastSuccessBg,
          borderColor: isDark
              ? const Color(0xFF2C5035)
              : ColorName.toastSuccessBorder,
          iconColor: isDark
              ? const Color(0xFF4CAF50)
              : ColorName.toastSuccessIcon,
          textColor: isDark
              ? const Color(0xFFE8F5E9)
              : ColorName.toastSuccessText,
          icon: Icons.check_circle_rounded,
        );

      case AppToastType.error:
        return _ToastConfig(
          backgroundColor: isDark
              ? const Color(0xFF2D1817)
              : ColorName.toastErrorBg,
          borderColor: isDark
              ? const Color(0xFF502725)
              : ColorName.toastErrorBorder,
          iconColor: isDark
              ? const Color(0xFFEF5350)
              : ColorName.toastErrorIcon,
          textColor: isDark
              ? const Color(0xFFFFEBEE)
              : ColorName.toastErrorText,
          icon: Icons.error_rounded,
        );

      case AppToastType.warning:
        return _ToastConfig(
          backgroundColor: isDark
              ? const Color(0xFF2E2512)
              : ColorName.toastWarningBg,
          borderColor: isDark
              ? const Color(0xFF514022)
              : ColorName.toastWarningBorder,
          iconColor: isDark
              ? const Color(0xFFFFB300)
              : ColorName.toastWarningIcon,
          textColor: isDark
              ? const Color(0xFFFFF8E1)
              : ColorName.toastWarningText,
          icon: Icons.warning_amber_rounded,
        );

      case AppToastType.info:
        return _ToastConfig(
          backgroundColor: isDark
              ? const Color(0xFF13273E)
              : ColorName.toastInfoBg,
          borderColor: isDark
              ? const Color(0xFF224268)
              : ColorName.toastInfoBorder,
          iconColor: isDark ? const Color(0xFF2196F3) : ColorName.toastInfoIcon,
          textColor: isDark ? const Color(0xFFE3F2FD) : ColorName.toastInfoText,
          icon: Icons.info_rounded,
        );

      case AppToastType.plain:
        return _ToastConfig(
          backgroundColor: isDark ? ColorName.surfaceDark : Colors.white,
          borderColor: isDark ? ColorName.greyDark : ColorName.toastPlainBorder,
          iconColor: isDark ? Colors.white70 : ColorName.toastPlainIcon,
          textColor: isDark ? Colors.white : ColorName.toastPlainText,
          icon: Icons.notifications_rounded,
        );
    }
  }

  // ============================================================
  // CLOSE ALL TOASTS
  // ============================================================

  static void closeAll() {
    BotToast.cleanAll();
  }
}

// ============================================================
// INTERNAL CONFIG MODEL
// ============================================================

class _ToastConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _ToastConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
