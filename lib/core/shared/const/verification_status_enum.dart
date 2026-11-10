enum VerificationStatus {
  pendingProfile('PENDING_PROFILE'),
  pendingVerification('PENDING_VERIFICATION'),
  underReview('UNDER_REVIEW'),
  verified('VERIFIED'),
  rejected('REJECTED'),
  blocked('BLOCKED'),
  unknown('UNKNOWN');

  final String value;

  const VerificationStatus(this.value);

  factory VerificationStatus.fromString(String? raw) {
    if (raw == null) {
      return VerificationStatus.unknown;
    }

    return VerificationStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => VerificationStatus.unknown,
    );
  }

  bool get isPendingProfile => this == VerificationStatus.pendingProfile;

  bool get isPendingVerification =>
      this == VerificationStatus.pendingVerification;

  bool get isUnderReview => this == VerificationStatus.underReview;

  bool get isVerified => this == VerificationStatus.verified;

  bool get isRejected => this == VerificationStatus.rejected;

  bool get isBlocked => this == VerificationStatus.blocked;

  bool get isUnknown => this == VerificationStatus.unknown;
}
