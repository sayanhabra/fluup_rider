enum NextStep {
  enterName('ENTER_NAME'),
  otpVerification('OTP_VERIFICATION'),
  profileSetup('PROFILE_SETUP'),
  pendingProfileSetup('PENDING_PROFILE'),
  verificationSubmission('VERIFICATION_SUBMISSION'),
  underReview('UNDER_REVIEW'),
  rejectedRetry('REJECTED_RETRY'),
  home('HOME'),
  unknown('UNKNOWN');

  final String value;
  const NextStep(this.value);

  factory NextStep.fromString(String? raw) {
    if (raw == null) return NextStep.unknown;
    return NextStep.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => NextStep.unknown,
    );
  }

  bool get isEnterName => this == NextStep.enterName;
  bool get isOtpVerification => this == NextStep.otpVerification;
  bool get isProfileSetup =>
      this == NextStep.profileSetup || this == NextStep.pendingProfileSetup;
  bool get isVerificationSubmission => this == NextStep.verificationSubmission;
  bool get isUnderReview => this == NextStep.underReview;
  bool get isRejectedRetry => this == NextStep.rejectedRetry;
  bool get isHome => this == NextStep.home;
}
