// modules/auth/screens/verification_submission_screen.dart

import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:adm_rider/core/shared/widgets/buttons.dart';
import 'package:adm_rider/modules/auth/screens/auth_status_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerificationSubmissionScreen extends ConsumerStatefulWidget {
  const VerificationSubmissionScreen({super.key});

  @override
  ConsumerState<VerificationSubmissionScreen> createState() =>
      _VerificationSubmissionScreenState();
}

class _VerificationSubmissionScreenState
    extends ConsumerState<VerificationSubmissionScreen> {
  final List<Map<String, dynamic>> _documents = [
    {
      'label': 'GST Certificate',
      'icon': Icons.description_outlined,
      'file': null,
    },
    {'label': 'PAN Card', 'icon': Icons.credit_card_outlined, 'file': null},
    {'label': 'Store Photo', 'icon': Icons.store_outlined, 'file': null},
    {
      'label': 'Bank Proof',
      'icon': Icons.account_balance_outlined,
      'file': null,
    },
  ];

  bool get _canSubmit => _documents.every((d) => d['file'] != null);

  Future<void> _pickFile(int index) async {
    // TODO: Implement file picker
    // final result = await FilePicker.platform.pickFiles();
    setState(() {
      _documents[index]['file'] = 'picked'; // placeholder
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();

    // TODO: Upload documents via apiService.uploadProfileDocument()
    // Then refresh auth state
  }

  @override
  Widget build(BuildContext context) {
    return AuthStatusScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ColorName.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 36,
                    color: ColorName.primary,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceLarge),
                Text(
                  'Verify Your Identity',
                  textAlign: TextAlign.center,
                  style: AppStyle.heading3.copyWith(
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceSmall),
                Text(
                  'Upload the required documents for verification',
                  textAlign: TextAlign.center,
                  style: AppStyle.bodyMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.spaceXXLarge),

          // ─── Document List ───
          ...List.generate(_documents.length, (index) {
            final doc = _documents[index];
            final isUploaded = doc['file'] != null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppStyle.spaceMedium),
              child: InkWell(
                onTap: () => _pickFile(index),
                borderRadius: AppStyle.borderRadiusMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppStyle.spaceLarge),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isUploaded
                          ? ColorName.primary
                          : AppStyle.borderColor,
                      width: isUploaded ? 2 : 1.5,
                    ),
                    borderRadius: AppStyle.borderRadiusMedium,
                    color: isUploaded
                        ? ColorName.primary.withValues(alpha: 0.04)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        doc['icon'] as IconData,
                        color: isUploaded
                            ? ColorName.primary
                            : AppStyle.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: AppStyle.spaceMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['label'] as String,
                              style: AppStyle.titleSmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUploaded ? 'Uploaded' : 'Tap to upload',
                              style: AppStyle.bodySmall.copyWith(
                                color: isUploaded
                                    ? ColorName.primary
                                    : AppStyle.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isUploaded
                            ? Icons.check_circle
                            : Icons.arrow_forward_ios,
                        color: isUploaded
                            ? ColorName.primary
                            : AppStyle.textSecondary,
                        size: isUploaded ? 24 : 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppStyle.spaceXXLarge),

          // ─── Submit ───
          SecondaryButton(
            text: 'Submit for Review',
            horizontalMargin: 0,
            height: 56,
            state: _canSubmit ? ButtonState.enabled : ButtonState.disabled,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
