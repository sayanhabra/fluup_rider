enum DocVerificationStatus {
  pending('PENDING'),
  autoVerified('AUTO_VERIFIED'),
  manualReview('MANUAL_REVIEW'),
  verified('VERIFIED'),
  rejected('REJECTED'),
  expired('EXPIRED'),
  unknown('UNKNOWN');

  final String value;
  const DocVerificationStatus(this.value);

  factory DocVerificationStatus.fromString(String? raw) {
    if (raw == null) return DocVerificationStatus.unknown;
    return DocVerificationStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => DocVerificationStatus.unknown,
    );
  }

  bool get isPending => this == DocVerificationStatus.pending;
  bool get isAutoVerified => this == DocVerificationStatus.autoVerified;
  bool get isManualReview => this == DocVerificationStatus.manualReview;
  bool get isVerified => this == DocVerificationStatus.verified;
  bool get isRejected => this == DocVerificationStatus.rejected;
  bool get isExpired => this == DocVerificationStatus.expired;
}
