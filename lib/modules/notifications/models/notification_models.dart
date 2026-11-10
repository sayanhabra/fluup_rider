// ============================================================
// Get Notification List
// ============================================================

class GetNotificationListResponse {
  final int statusCode;
  final String message;
  final NotificationResponse response;

  GetNotificationListResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory GetNotificationListResponse.fromJson(Map<String, dynamic> json) {
    return GetNotificationListResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      response: NotificationResponse.fromJson(json['response'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

class NotificationResponse {
  final List<NotificationItem> data;
  final Pagination pagination;

  NotificationResponse({required this.data, required this.pagination});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => NotificationItem.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class NotificationItem {
  final int id;
  final int receiverId;
  final String title;
  final String message;
  final String type;
  final String portal;
  final bool isRead;
  final NotificationData? data;
  final String? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationItem({
    required this.id,
    required this.receiverId,
    required this.title,
    required this.message,
    required this.type,
    required this.portal,
    required this.isRead,
    this.data,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      portal: json['portal'] ?? '',
      isRead: json['isRead'] ?? false,
      data: json['data'] != null
          ? NotificationData.fromJson(json['data'])
          : null,
      deletedAt: json['deletedAt'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverId': receiverId,
      'title': title,
      'message': message,
      'type': type,
      'portal': portal,
      'isRead': isRead,
      'data': data?.toJson(),
      'deletedAt': deletedAt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    int? id,
    int? receiverId,
    String? title,
    String? message,
    String? type,
    String? portal,
    bool? isRead,
    NotificationData? data,
    String? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      portal: portal ?? this.portal,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NotificationData {
  final String type;
  final String event;
  final String sound;
  final String webUrl;
  final String deepLink;
  final String entityId;
  final String priority;
  final String actionLabel;

  NotificationData({
    required this.type,
    required this.event,
    required this.sound,
    required this.webUrl,
    required this.deepLink,
    required this.entityId,
    required this.priority,
    required this.actionLabel,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      type: json['type'] ?? '',
      event: json['event'] ?? '',
      sound: json['sound'] ?? 'default',
      webUrl: json['webUrl'] ?? '',
      deepLink: json['deepLink'] ?? '',
      entityId: json['entityId'] ?? '',
      priority: json['priority'] ?? 'NORMAL',
      actionLabel: json['actionLabel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'event': event,
      'sound': sound,
      'webUrl': webUrl,
      'deepLink': deepLink,
      'entityId': entityId,
      'priority': priority,
      'actionLabel': actionLabel,
    };
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;

  Pagination({required this.total, required this.page, required this.limit});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'page': page, 'limit': limit};
  }
}

// ============================================================
// Unread Count
// ============================================================

class UnreadCountNotificationResponse {
  final int statusCode;
  final String message;
  final UnreadCountData response;

  UnreadCountNotificationResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory UnreadCountNotificationResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountNotificationResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      response: UnreadCountData.fromJson(json['response'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

class UnreadCountData {
  final int unreadCount;
  final bool hasUnread;

  UnreadCountData({required this.unreadCount, required this.hasUnread});

  factory UnreadCountData.fromJson(Map<String, dynamic> json) {
    return UnreadCountData(
      unreadCount: json['unreadCount'] ?? 0,
      hasUnread: json['hasUnread'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'unreadCount': unreadCount, 'hasUnread': hasUnread};
  }
}

// ============================================================
// Make Single Notification As Read
// ============================================================

class MakeSingleNotificationAsReadResponse {
  final int statusCode;
  final String message;
  final NotificationItem response;

  MakeSingleNotificationAsReadResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory MakeSingleNotificationAsReadResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MakeSingleNotificationAsReadResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      response: NotificationItem.fromJson(json['response'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

// ============================================================
// Delete Notification
// ============================================================

class DeleteNotificationResponse {
  final int statusCode;
  final String message;
  final NotificationItem response;

  DeleteNotificationResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory DeleteNotificationResponse.fromJson(Map<String, dynamic> json) {
    return DeleteNotificationResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      response: NotificationItem.fromJson(json['response'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

// ============================================================
// Make All Notifications As Read
// ============================================================

class MakeAllNotificationAsReadResponse {
  final int statusCode;
  final String message;
  final MakeAllReadData response;

  MakeAllNotificationAsReadResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory MakeAllNotificationAsReadResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MakeAllNotificationAsReadResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      response: MakeAllReadData.fromJson(json['response'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

class MakeAllReadData {
  final bool success;

  MakeAllReadData({required this.success});

  factory MakeAllReadData.fromJson(Map<String, dynamic> json) {
    return MakeAllReadData(success: json['success'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'success': success};
  }
}
