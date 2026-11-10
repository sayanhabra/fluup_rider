// modules/auth/models/set_profile_submit_response.dart

class SetProfileSubmitResponse {
  final int? statusCode;
  final String? message;
  final SetProfileSubmitResponseData? response;

  SetProfileSubmitResponse({this.statusCode, this.message, this.response});

  factory SetProfileSubmitResponse.fromJson(Map<String, dynamic> json) {
    return SetProfileSubmitResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      response: json['response'] != null
          ? SetProfileSubmitResponseData.fromJson(json['response'])
          : null,
    );
  }
}

class SetProfileSubmitResponseData {
  final int? userId;
  final String? name;
  final String? verificationStatus;
  final String? nextStep;
  final double? faceMatchScore;

  SetProfileSubmitResponseData({
    this.userId,
    this.name,
    this.verificationStatus,
    this.nextStep,
    this.faceMatchScore,
  });

  factory SetProfileSubmitResponseData.fromJson(Map<String, dynamic> json) {
    return SetProfileSubmitResponseData(
      userId: json['userId'],
      name: json['name'],
      verificationStatus: json['verificationStatus'],
      nextStep: json['nextStep'],
      faceMatchScore: (json['faceMatchScore'] as num?)?.toDouble(),
    );
  }
}
