import 'package:adm_rider/core/shared/const/next_step_enum.dart';
import 'package:adm_rider/core/shared/const/verification_status_enum.dart';

// ==========================================
// 1. NEW RIDER DETAILS MODEL
// ==========================================
class RiderDetails {
  final String? dateOfBirth;
  final String? gender;
  final String? documentType;
  final String? documentNumber;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String? drivingLicenseNumber;
  final String? drivingLicenseExpiryDate;
  final String? drivingLicenseDocumentUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? selfieUrl;
  final double? faceMatchScore;
  final DateTime? kycVerifiedAt;

  const RiderDetails({
    this.dateOfBirth,
    this.gender,
    this.documentType,
    this.documentNumber,
    this.documentFrontUrl,
    this.documentBackUrl,
    this.drivingLicenseNumber,
    this.drivingLicenseExpiryDate,
    this.drivingLicenseDocumentUrl,
    this.vehicleType,
    this.vehicleNumber,
    this.selfieUrl,
    this.faceMatchScore,
    this.kycVerifiedAt,
  });

  factory RiderDetails.fromJson(Map<String, dynamic> json) {
    return RiderDetails(
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      documentType: json['documentType'] as String?,
      documentNumber: json['documentNumber'] as String?,
      documentFrontUrl: json['documentFrontUrl'] as String?,
      documentBackUrl: json['documentBackUrl'] as String?,
      drivingLicenseNumber: json['drivingLicenseNumber'] as String?,
      drivingLicenseExpiryDate: json['drivingLicenseExpiryDate'] as String?,
      drivingLicenseDocumentUrl: json['drivingLicenseDocumentUrl'] as String?,
      vehicleType: json['vehicleType'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      selfieUrl: json['selfieUrl'] as String?,
      faceMatchScore: json['faceMatchScore'] != null
          ? double.tryParse(json['faceMatchScore'].toString())
          : null,
      kycVerifiedAt: json['kycVerifiedAt'] != null
          ? DateTime.tryParse(json['kycVerifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentFrontUrl': documentFrontUrl,
      'documentBackUrl': documentBackUrl,
      'drivingLicenseNumber': drivingLicenseNumber,
      'drivingLicenseExpiryDate': drivingLicenseExpiryDate,
      'drivingLicenseDocumentUrl': drivingLicenseDocumentUrl,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'selfieUrl': selfieUrl,
      'faceMatchScore': faceMatchScore,
      'kycVerifiedAt': kycVerifiedAt?.toIso8601String(),
    };
  }
}

// ==========================================
// 2. UPDATED USER MODEL
// ==========================================
class UserModel {
  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? profileImagePath;
  final String? profileImage;
  final String role;
  final VerificationStatus verificationStatus;
  final NextStep nextStep;
  final String? rejectionReason;
  final RiderDetails? riderDetails;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.profileImagePath,
    this.profileImage,
    required this.role,
    required this.verificationStatus,
    required this.nextStep,
    this.rejectionReason,
    this.riderDetails,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImagePath: json['profileImagePath'] as String?,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? 'USER',
      verificationStatus: VerificationStatus.fromString(
        json['verificationStatus'] as String?,
      ),
      nextStep: NextStep.fromString(json['nextStep'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      riderDetails: json['riderDetails'] != null
          ? RiderDetails.fromJson(json['riderDetails'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'profileImagePath': profileImagePath,
      'profileImage': profileImage,
      'role': role,
      'verificationStatus': verificationStatus.value,
      'nextStep': nextStep.value,
      'rejectionReason': rejectionReason,
      'riderDetails': riderDetails?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ─── Convenience Getters (Proxy to RiderDetails) ───

  String? get dateOfBirth => riderDetails?.dateOfBirth;
  String? get gender => riderDetails?.gender;
  String? get panNumber =>
      null; // Not present in JSON, but keeping for compatibility if you add it later
  String? get documentType => riderDetails?.documentType;
  String? get documentNumber => riderDetails?.documentNumber;
  String? get documentFrontUrl => riderDetails?.documentFrontUrl;
  String? get documentBackUrl => riderDetails?.documentBackUrl;
  String? get selfieUrl => riderDetails?.selfieUrl;
  double? get faceMatchScore => riderDetails?.faceMatchScore;
  DateTime? get kycVerifiedAt => riderDetails?.kycVerifiedAt;

  String? get drivingLicenseNumber => riderDetails?.drivingLicenseNumber;
  String? get drivingLicenseExpiryDate =>
      riderDetails?.drivingLicenseExpiryDate;
  String? get drivingLicenseDocumentUrl =>
      riderDetails?.drivingLicenseDocumentUrl;
  String? get vehicleType => riderDetails?.vehicleType;
  String? get vehicleNumber => riderDetails?.vehicleNumber;

  // ─── Helper Properties ───

  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  bool get hasPanNumber => panNumber != null && panNumber!.isNotEmpty;

  bool get hasDocument => documentType != null && documentNumber != null;

  bool get hasDocumentImages =>
      documentFrontUrl != null || documentBackUrl != null;

  bool get hasSelfie => selfieUrl != null && selfieUrl!.isNotEmpty;

  bool get isKycVerified => kycVerifiedAt != null;

  bool get isRejected => rejectionReason != null && rejectionReason!.isNotEmpty;

  // ─── Verification Status Helpers ───

  bool get isPendingProfile => verificationStatus.isPendingProfile;
  bool get isPendingVerification => verificationStatus.isPendingVerification;
  bool get isUnderReview => verificationStatus.isUnderReview;
  bool get isVerified => verificationStatus.isVerified;
  bool get isRejectedStatus => verificationStatus.isRejected;
  bool get isBlocked => verificationStatus.isBlocked;

  // ─── Next Step Helpers ───

  bool get needsEnterName => nextStep.isEnterName;
  bool get needsOtpVerification => nextStep.isOtpVerification;
  bool get needsProfileSetup => nextStep.isProfileSetup;
  bool get needsVerificationSubmission => nextStep.isVerificationSubmission;
  bool get isUnderReviewStatus => nextStep.isUnderReview;
  bool get isRejectedRetry => nextStep.isRejectedRetry;
  bool get shouldGoHome => nextStep.isHome;

  // ─── Display Helpers ───

  String get displayName => name ?? 'User';

  String get displayRole =>
      role.substring(0, 1).toUpperCase() + role.substring(1).toLowerCase();

  String get formattedCreatedAt {
    if (createdAt == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'Not provided';
    try {
      final date = DateTime.parse(dateOfBirth!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateOfBirth!;
    }
  }

  String get genderDisplay {
    if (gender == null) return 'Not specified';
    return gender!.substring(0, 1).toUpperCase() +
        gender!.substring(1).toLowerCase();
  }

  String get documentTypeDisplay {
    if (documentType == null) return 'Not provided';
    return documentType!.replaceAll('_', ' ').toUpperCase();
  }

  String get verificationStatusDisplay {
    return verificationStatus.value.replaceAll('_', ' ').toUpperCase();
  }

  String get nextStepDisplay {
    return nextStep.value.replaceAll('_', ' ').toUpperCase();
  }

  // ─── Navigation Helpers ───

  String? get nextScreenRoute {
    if (nextStep.isEnterName) {
      return '/enter-name';
    } else if (nextStep.isOtpVerification) {
      return '/verify-otp';
    } else if (nextStep.isProfileSetup) {
      return '/profile-setup';
    } else if (nextStep.isVerificationSubmission) {
      return '/kyc-verification';
    } else if (nextStep.isUnderReview) {
      return '/profile';
    } else if (nextStep.isRejectedRetry) {
      return '/kyc-retry';
    } else if (nextStep.isHome) {
      return '/home';
    }
    return null;
  }

  // ─── Copy With ───

  UserModel copyWith({
    int? id,
    String? phone,
    String? name,
    String? email,
    String? profileImagePath,
    String? profileImage,
    String? role,
    VerificationStatus? verificationStatus,
    NextStep? nextStep,
    String? rejectionReason,
    RiderDetails? riderDetails,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      nextStep: nextStep ?? this.nextStep,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      riderDetails: riderDetails ?? this.riderDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ───

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.phone == phone &&
        other.name == name &&
        other.email == email &&
        other.profileImagePath == profileImagePath &&
        other.profileImage == profileImage &&
        other.role == role &&
        other.verificationStatus == verificationStatus &&
        other.nextStep == nextStep &&
        other.rejectionReason == rejectionReason &&
        other.riderDetails == riderDetails &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      phone,
      name,
      email,
      profileImagePath,
      profileImage,
      role,
      verificationStatus,
      nextStep,
      rejectionReason,
      riderDetails,
      createdAt,
    ]);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, phone: $phone, status: ${verificationStatus.value}, nextStep: ${nextStep.value})';
  }
}
