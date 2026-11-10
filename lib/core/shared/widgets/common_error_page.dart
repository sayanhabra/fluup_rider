import 'dart:math';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/widgets/buttons.dart';
import 'package:adm_rider/core/shared/widgets/gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommonErrorPage<T> extends ConsumerWidget {
  const CommonErrorPage({
    super.key,
    required this.error,
    required this.stackTrace,
    this.provider,
    this.onPressed,
    this.buttonText,
  });
  final String error;
  final StackTrace stackTrace;
  final Refreshable<T>? provider;
  final void Function()? onPressed;
  final String? buttonText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ColorName.greySecond,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // commonErrorImage,
              const Gap(55),
              Text(
                error,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const Gap(13),
              Text(
                stackTrace.toString().substring(
                  0,
                  min(200, stackTrace.toString().length),
                ),
              ),
              const Gap(30),
              provider == null
                  ? BorderButton(onPressed: onPressed, text: buttonText)
                  : BorderButton(
                      onPressed: () async => ref.refresh(provider!),
                      text: 'Try again',
                    ),
              // AppButton(
              //   onPressed: () async => ref.refresh(provider),
              //   child: const Text('Try again'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
