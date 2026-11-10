// modules/auth/screens/profile_setup_screen.dart

import 'dart:io';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/core/shared/const/next_step_enum.dart';
import 'package:adm_rider/core/shared/const/verification_status_enum.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:adm_rider/core/shared/widgets/buttons.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/auth/screens/auth_status_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  // ─── Controllers ───
  final _documentNumber = TextEditingController();
  final _fullName = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _drivingLicenseNumber = TextEditingController();
  final _drivingLicenseExpiryDate = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehicleNumber = TextEditingController();

  String _documentType = 'AADHAAR_CARD';
  String _gender = 'Male';

  // ─── File States ───
  File? _documentFront;
  File? _documentBack;
  File? _selfie;
  File? _drivingLicenseDocument;

  bool _isLoading = false;
  String? _errorText;

  final ImagePicker _picker = ImagePicker();

  // ─── Validation ───
  bool get _isFormValid {
    return _documentNumber.text.trim().isNotEmpty &&
        _fullName.text.trim().isNotEmpty &&
        _dateOfBirth.text.trim().isNotEmpty &&
        _drivingLicenseNumber.text.trim().isNotEmpty &&
        _drivingLicenseExpiryDate.text.trim().isNotEmpty &&
        _vehicleType.text.trim().isNotEmpty &&
        _vehicleNumber.text.trim().isNotEmpty &&
        _documentFront != null &&
        _selfie != null &&
        _drivingLicenseDocument != null;
  }

  @override
  void dispose() {
    _documentNumber.dispose();
    _fullName.dispose();
    _dateOfBirth.dispose();
    _drivingLicenseNumber.dispose();
    _drivingLicenseExpiryDate.dispose();
    _vehicleType.dispose();
    _vehicleNumber.dispose();
    super.dispose();
  }

  // ─── Pick Date ───
  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ColorName.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  // ─── Pick Image ───
  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (type == 'front') _documentFront = File(image.path);
          if (type == 'back') _documentBack = File(image.path);
          if (type == 'selfie') _selfie = File(image.path);
          if (type == 'license') _drivingLicenseDocument = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // ─── Submit ───
  Future<void> _submitProfile() async {
    if (!_isFormValid) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final data = {
        'documentType': _documentType,
        'documentNumber': _documentNumber.text.trim(),
        'fullName': _fullName.text.trim(),
        'dateOfBirth': _dateOfBirth.text.trim(),
        'gender': _gender,
        'drivingLicenseNumber': _drivingLicenseNumber.text.trim(),
        'drivingLicenseExpiryDate': _drivingLicenseExpiryDate.text.trim(),
        'vehicleType': _vehicleType.text.trim(),
        'vehicleNumber': _vehicleNumber.text.trim(),
      };

      final response = await ref
          .read(apiServiceProvider)
          .setProfile(
            data: data,
            documentFront: _documentFront!,
            documentBack: _documentBack,
            selfie: _selfie!,
            drivingLicenseDocument: _drivingLicenseDocument!,
          );

      if (response.response != null) {
        // 1. Parse the VerificationStatus
        final newStatusStr = response.response!.verificationStatus;
        final newStatus = VerificationStatus.fromString(newStatusStr);

        // 2. Parse the NextStep
        final nextStepStr = response.response!.nextStep;
        final nextStep = NextStep.fromString(nextStepStr);

        // 3. Update the auth state with BOTH arguments
        await ref
            .read(authNotifierProvider.notifier)
            .updateUserVerificationStatus(newStatus, nextStep);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorText = errorMessage;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AuthStatusScaffold(
      isLoading: _isLoading,
      loadingMessage: 'Submitting verification... ⏳',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════
          Center(
            child: Column(
              children: [
                Text(
                  'Submit Verification',
                  textAlign: TextAlign.center,
                  style: AppStyle.heading3.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceSmall),
                Text(
                  'Complete your KYC to start riding',
                  textAlign: TextAlign.center,
                  style: AppStyle.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.spaceXXLarge),

          // ═══════════════════════════════════════════════════════
          // IDENTITY DETAILS
          // ═══════════════════════════════════════════════════════
          _sectionTitle('Identity Details'),
          const SizedBox(height: AppStyle.spaceMedium),

          _buildDropdownField(
            label: 'Document Type *',
            value: _documentType,
            items: const [
              {'label': 'AADHAAR CARD', 'value': 'AADHAAR_CARD'},
              {'label': 'PASSPORT', 'value': 'PASSPORT'},
              {'label': 'VOTER ID', 'value': 'VOTER_ID'},
            ],
            onChanged: (val) {
              if (val != null) setState(() => _documentType = val);
            },
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          _buildField(
            keyboardType: _documentType == 'AADHAAR_CARD'
                ? TextInputType.number
                : TextInputType.text,
            controller: _documentNumber,
            label: 'Document Number *',
            hint: '1234 5678 9012',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          _buildField(
            controller: _fullName,
            label: 'Full Name *',
            hint: 'Rahul Kumar',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _dateOfBirth,
                  label: 'Date of Birth *',
                  hint: '1998-05-15',
                ),
              ),
              const SizedBox(width: AppStyle.spaceMedium),
              Expanded(
                child: _buildDropdownField(
                  label: 'Gender *',
                  value: _gender,
                  items: const [
                    {'label': 'Male', 'value': 'Male'},
                    {'label': 'Female', 'value': 'Female'},
                    {'label': 'Other', 'value': 'Other'},
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyle.spaceXLarge),

          // ═══════════════════════════════════════════════════════
          // DRIVING LICENSE
          // ═══════════════════════════════════════════════════════
          _sectionTitle('Driving License'),
          const SizedBox(height: AppStyle.spaceMedium),
          _buildField(
            controller: _drivingLicenseNumber,
            label: 'License Number *',
            hint: 'DL0420110012345',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppStyle.spaceLarge),
          _buildDateField(
            controller: _drivingLicenseExpiryDate,
            label: 'Expiry Date *',
            hint: '2030-05-15',
          ),
          const SizedBox(height: AppStyle.spaceXLarge),

          // ═══════════════════════════════════════════════════════
          // VEHICLE DETAILS
          // ═══════════════════════════════════════════════════════
          _sectionTitle('Vehicle Details'),
          const SizedBox(height: AppStyle.spaceMedium),
          _buildField(
            controller: _vehicleType,
            label: 'Vehicle Type *',
            hint: 'MOTORCYCLE',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppStyle.spaceLarge),
          _buildField(
            controller: _vehicleNumber,
            label: 'Vehicle Number *',
            hint: 'KA01AB1234',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppStyle.spaceXLarge),

          // ═══════════════════════════════════════════════════════
          // DOCUMENTS UPLOAD
          // ═══════════════════════════════════════════════════════
          _sectionTitle('Upload Documents'),
          const SizedBox(height: AppStyle.spaceMedium),

          _buildFilePicker(
            label: 'Document Front *',
            file: _documentFront,
            onTap: () => _pickImage('front'),
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          _buildFilePicker(
            label: 'Document Back (Optional)',
            file: _documentBack,
            onTap: () => _pickImage('back'),
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          _buildFilePicker(
            label: 'Selfie *',
            file: _selfie,
            onTap: () => _pickImage('selfie'),
          ),
          const SizedBox(height: AppStyle.spaceLarge),

          _buildFilePicker(
            label: 'Driving License Doc *',
            file: _drivingLicenseDocument,
            onTap: () => _pickImage('license'),
          ),
          const SizedBox(height: AppStyle.spaceXXLarge),

          // ═══════════════════════════════════════════════════════
          // ERROR
          // ═══════════════════════════════════════════════════════
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppStyle.spaceMedium),
              child: Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: AppStyle.bodySmall.copyWith(
                  color: isDark ? Colors.redAccent : Colors.red.shade700,
                ),
              ),
            ),

          // ═══════════════════════════════════════════════════════
          // SUBMIT
          // ═══════════════════════════════════════════════════════
          SecondaryButton(
            text: 'Submit Verification',
            horizontalMargin: 0,
            height: 56,
            state: _isLoading
                ? ButtonState.loading
                : _isFormValid
                ? ButtonState.enabled
                : ButtonState.disabled,
            onPressed: _submitProfile,
          ),
          const SizedBox(height: AppStyle.spaceXLarge),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppStyle.titleLarge.copyWith(
        color: ColorName.primaryBrandRed,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.titleMedium.copyWith(
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSmall),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(context, hint: hint),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.titleMedium.copyWith(
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSmall),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e['value'],
                  child: Text(e['label']!),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(context, hint: ''),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.titleMedium.copyWith(
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSmall),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickDate(controller),
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(context, hint: hint).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: ColorName.primaryBrandRed,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.titleMedium.copyWith(
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSmall),
        InkWell(
          onTap: onTap,
          borderRadius: AppStyle.borderRadiusMedium,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyle.spaceLarge,
              vertical: AppStyle.spaceLarge,
            ),
            decoration: BoxDecoration(
              borderRadius: AppStyle.borderRadiusMedium,
              border: Border.all(
                color: file != null
                    ? ColorName.primaryBrandRed
                    : context.customColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null
                      ? ColorName.primaryBrandRed
                      : (isDark ? Colors.white54 : Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.path.split('/').last : 'Choose File',
                    style: AppStyle.bodyMedium.copyWith(
                      color: file != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : ColorName.lightGreyBorder,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final isDark = context.isDarkMode;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppStyle.bodyMedium.copyWith(color: ColorName.lightGreyBorder),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppStyle.spaceLarge,
        vertical: AppStyle.spaceLarge,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyle.borderRadiusMedium,
        borderSide: BorderSide(color: context.customColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyle.borderRadiusMedium,
        borderSide: BorderSide(
          color: isDark ? ColorName.secondary : ColorName.primaryBrandRed,
          width: 2,
        ),
      ),
    );
  }
}
