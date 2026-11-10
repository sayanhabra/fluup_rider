import 'package:adm_rider/core/shared/const/doc_varification_enum.dart';
import 'package:adm_rider/core/shared/const/verification_status_enum.dart';

// ==================== NESTED DATA MODEL ====================

class SellerProfileData {
  final int userId;
  final String storeName;
  final String? storeDescription;
  final String licenseNumber;
  final String licenseHolderName;
  final String licenseType;
  final DateTime? licenseIssueDate;
  final DateTime? licenseExpiryDate;
  final String? licenseDocumentUrl;
  final DocVerificationStatus licenseVerificationStatus;
  final DateTime? licenseVerifiedAt;
  final int? licenseVerifiedById;
  final String gstin;
  final String panNumber;
  final bool isDocAutoVerified;
  final String? verificationProvider;
  final String? docVerificationNotes;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final dynamic businessHours;
  final bool isStoreOpen;
  final bool isManualOverride;
  final VerificationStatus status;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SellerProfileData({
    required this.userId,
    required this.storeName,
    this.storeDescription,
    required this.licenseNumber,
    required this.licenseHolderName,
    required this.licenseType,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    this.licenseDocumentUrl,
    required this.licenseVerificationStatus,
    this.licenseVerifiedAt,
    this.licenseVerifiedById,
    required this.gstin,
    required this.panNumber,
    required this.isDocAutoVerified,
    this.verificationProvider,
    this.docVerificationNotes,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.businessHours,
    required this.isStoreOpen,
    required this.isManualOverride,
    required this.status,
    this.bankAccountNumber,
    this.ifscCode,
    this.upiId,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerProfileData.fromJson(Map<String, dynamic> json) {
    return SellerProfileData(
      userId: json['userId'] as int? ?? 0,
      storeName: json['storeName'] as String? ?? '',
      storeDescription: json['storeDescription'] as String?,
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseHolderName: json['licenseHolderName'] as String? ?? '',
      licenseType: json['licenseType'] as String? ?? '',
      licenseIssueDate: _parseDate(json['licenseIssueDate']),
      licenseExpiryDate: _parseDate(json['licenseExpiryDate']),
      licenseDocumentUrl: json['licenseDocumentUrl'] as String?,
      licenseVerificationStatus: DocVerificationStatus.fromString(
        json['licenseVerificationStatus'] as String?,
      ),
      licenseVerifiedAt: _parseDate(json['licenseVerifiedAt']),
      licenseVerifiedById: json['licenseVerifiedById'] as int?,
      gstin: json['gstin'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      isDocAutoVerified: json['isDocAutoVerified'] as bool? ?? false,
      verificationProvider: json['verificationProvider'] as String?,
      docVerificationNotes: json['docVerificationNotes'] as String?,
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      businessHours: json['businessHours'],
      isStoreOpen: json['isStoreOpen'] as bool? ?? false,
      isManualOverride: json['isManualOverride'] as bool? ?? false,
      status: VerificationStatus.fromString(json['status'] as String?),
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      upiId: json['upiId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'storeName': storeName,
      'storeDescription': storeDescription,
      'licenseNumber': licenseNumber,
      'licenseHolderName': licenseHolderName,
      'licenseType': licenseType,
      'licenseIssueDate': licenseIssueDate?.toIso8601String(),
      'licenseExpiryDate': licenseExpiryDate?.toIso8601String(),
      'licenseDocumentUrl': licenseDocumentUrl,
      'licenseVerificationStatus': licenseVerificationStatus.value,
      'licenseVerifiedAt': licenseVerifiedAt?.toIso8601String(),
      'licenseVerifiedById': licenseVerifiedById,
      'gstin': gstin,
      'panNumber': panNumber,
      'isDocAutoVerified': isDocAutoVerified,
      'verificationProvider': verificationProvider,
      'docVerificationNotes': docVerificationNotes,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'businessHours': businessHours,
      'isStoreOpen': isStoreOpen,
      'isManualOverride': isManualOverride,
      'status': status.value,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  SellerProfileData copyWith({
    int? userId,
    String? storeName,
    String? storeDescription,
    String? licenseNumber,
    String? licenseHolderName,
    String? licenseType,
    DateTime? licenseIssueDate,
    DateTime? licenseExpiryDate,
    String? licenseDocumentUrl,
    DocVerificationStatus? licenseVerificationStatus,
    DateTime? licenseVerifiedAt,
    int? licenseVerifiedById,
    String? gstin,
    String? panNumber,
    bool? isDocAutoVerified,
    String? verificationProvider,
    String? docVerificationNotes,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    dynamic businessHours,
    bool? isStoreOpen,
    bool? isManualOverride,
    VerificationStatus? status,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerProfileData(
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseHolderName: licenseHolderName ?? this.licenseHolderName,
      licenseType: licenseType ?? this.licenseType,
      licenseIssueDate: licenseIssueDate ?? this.licenseIssueDate,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      licenseVerificationStatus:
          licenseVerificationStatus ?? this.licenseVerificationStatus,
      licenseVerifiedAt: licenseVerifiedAt ?? this.licenseVerifiedAt,
      licenseVerifiedById: licenseVerifiedById ?? this.licenseVerifiedById,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      isDocAutoVerified: isDocAutoVerified ?? this.isDocAutoVerified,
      verificationProvider: verificationProvider ?? this.verificationProvider,
      docVerificationNotes: docVerificationNotes ?? this.docVerificationNotes,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      businessHours: businessHours ?? this.businessHours,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      status: status ?? this.status,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'SellerProfileData(userId: $userId, storeName: $storeName, status: ${status.value})';
}

// ==================== WRAPPER RESPONSE ====================

class SellerProfileResponse {
  final int statusCode;
  final String message;
  final SellerProfileData response;

  const SellerProfileResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory SellerProfileResponse.fromJson(Map<String, dynamic> json) {
    return SellerProfileResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      response: SellerProfileData.fromJson(
        json['response'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;

  @override
  String toString() =>
      'SellerProfileResponse(statusCode: $statusCode, message: $message)';
}
