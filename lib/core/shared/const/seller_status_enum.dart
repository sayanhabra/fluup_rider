// enum SellerStatus {
//   draft('DRAFT'),
//   pendingApproval('PENDING_APPROVAL'),
//   autoVerified('AUTO_VERIFIED'),
//   manualReviewRequired('MANUAL_REVIEW_REQUIRED'),
//   verified('VERIFIED'),
//   rejected('REJECTED'),
//   suspended('SUSPENDED'),
//   unknown('UNKNOWN');

//   final String value;
//   const SellerStatus(this.value);

//   factory SellerStatus.fromString(String? raw) {
//     if (raw == null) return SellerStatus.unknown;

//     return SellerStatus.values.firstWhere(
//       (e) => e.value == raw,
//       orElse: () => SellerStatus.unknown,
//     );
//   }

//   bool get isDraft => this == SellerStatus.draft;

//   bool get isPendingApproval => this == SellerStatus.pendingApproval;

//   bool get isAutoVerified => this == SellerStatus.autoVerified;

//   bool get isManualReviewRequired => this == SellerStatus.manualReviewRequired;

//   bool get isVerified => this == SellerStatus.verified;

//   bool get isRejected => this == SellerStatus.rejected;

//   bool get isSuspended => this == SellerStatus.suspended;

//   bool get isUnknown => this == SellerStatus.unknown;
// }
