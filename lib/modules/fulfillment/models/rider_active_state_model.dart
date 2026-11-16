enum RiderStateType {
  idle('IDLE'),
  activeOffer('ACTIVE_OFFER'),
  activeDelivery('ACTIVE_DELIVERY');

  final String value;
  const RiderStateType(this.value);

  static RiderStateType fromString(String? val) {
    if (val == null) return RiderStateType.idle;
    for (final type in RiderStateType.values) {
      if (type.value.toUpperCase() == val.toUpperCase()) {
        return type;
      }
    }
    return RiderStateType.idle;
  }
}

double parseCoordinate(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString().trim()) ?? 0.0;
}

class RiderOfferPreview {
  final int orderId;
  final String orderNumber;
  final int attemptId;
  final String storeName;
  final String storeAddress;
  final double storeLatitude;
  final double storeLongitude;
  final String deliveryArea;
  final double? distanceKm;
  final int totalItems;
  final int totalVolumeMl;
  final int estimatedEarningsPaisa;
  final int remainingSeconds;
  final DateTime? expiresAt;

  const RiderOfferPreview({
    required this.orderId,
    required this.orderNumber,
    required this.attemptId,
    required this.storeName,
    required this.storeAddress,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.deliveryArea,
    this.distanceKm,
    required this.totalItems,
    required this.totalVolumeMl,
    required this.estimatedEarningsPaisa,
    required this.remainingSeconds,
    this.expiresAt,
  });

  String get formattedEarnings =>
      '₹${(estimatedEarningsPaisa / 100).toStringAsFixed(0)}';

  String get formattedVolume => totalVolumeMl >= 1000
      ? '${(totalVolumeMl / 1000).toStringAsFixed(1)} L'
      : '$totalVolumeMl ml';

  factory RiderOfferPreview.fromJson(Map<String, dynamic> json) {
    final expStr = json['expiresAt']?.toString();
    return RiderOfferPreview(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber']?.toString() ?? '',
      attemptId: (json['attemptId'] as num?)?.toInt() ?? 0,
      storeName: json['storeName']?.toString() ?? '',
      storeAddress: json['storeAddress']?.toString() ?? '',
      storeLatitude: parseCoordinate(
        json['storeLatitude'] ?? json['store_latitude'] ?? json['latitude'] ?? json['lat'],
      ),
      storeLongitude: parseCoordinate(
        json['storeLongitude'] ?? json['store_longitude'] ?? json['longitude'] ?? json['lng'],
      ),
      deliveryArea: json['deliveryArea']?.toString() ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalVolumeMl: (json['totalVolumeMl'] as num?)?.toInt() ?? 0,
      estimatedEarningsPaisa:
          (json['estimatedEarningsPaisa'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
      expiresAt: expStr != null ? DateTime.tryParse(expStr) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'attemptId': attemptId,
        'storeName': storeName,
        'storeAddress': storeAddress,
        'storeLatitude': storeLatitude,
        'storeLongitude': storeLongitude,
        'deliveryArea': deliveryArea,
        'distanceKm': distanceKm,
        'totalItems': totalItems,
        'totalVolumeMl': totalVolumeMl,
        'estimatedEarningsPaisa': estimatedEarningsPaisa,
        'remainingSeconds': remainingSeconds,
        'expiresAt': expiresAt?.toIso8601String(),
      };
}

class ActiveDeliveryStore {
  final String name;
  final String licenseNumber;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;

  const ActiveDeliveryStore({
    required this.name,
    required this.licenseNumber,
    required this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
  });

  factory ActiveDeliveryStore.fromJson(Map<String, dynamic> json) {
    return ActiveDeliveryStore(
      name: json['name']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      latitude: parseCoordinate(
        json['latitude'] ?? json['lat'] ?? json['storeLatitude'],
      ),
      longitude: parseCoordinate(
        json['longitude'] ?? json['lng'] ?? json['storeLongitude'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'licenseNumber': licenseNumber,
        'address': address,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class ActiveDeliveryCustomer {
  final String name;
  final String phone;
  final String deliveryAddress;
  final String pincode;
  final double latitude;
  final double longitude;

  const ActiveDeliveryCustomer({
    required this.name,
    required this.phone,
    required this.deliveryAddress,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  factory ActiveDeliveryCustomer.fromJson(Map<String, dynamic> json) {
    return ActiveDeliveryCustomer(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: parseCoordinate(
        json['latitude'] ?? json['lat'] ?? json['deliveryLatitude'],
      ),
      longitude: parseCoordinate(
        json['longitude'] ?? json['lng'] ?? json['deliveryLongitude'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'deliveryAddress': deliveryAddress,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class ActiveDeliveryItem {
  final int id;
  final String productName;
  final String? variantName;
  final int quantity;
  final String? packageSize;
  final int volumeMl;
  final String? productImage;

  const ActiveDeliveryItem({
    required this.id,
    required this.productName,
    this.variantName,
    required this.quantity,
    this.packageSize,
    required this.volumeMl,
    this.productImage,
  });

  factory ActiveDeliveryItem.fromJson(Map<String, dynamic> json) {
    return ActiveDeliveryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      packageSize: json['packageSize']?.toString(),
      volumeMl: (json['volumeMl'] as num?)?.toInt() ?? 0,
      productImage: json['productImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'variantName': variantName,
        'quantity': quantity,
        'packageSize': packageSize,
        'volumeMl': volumeMl,
        'productImage': productImage,
      };
}

class ActiveDeliveryMilestones {
  final DateTime? assignedAt;
  final DateTime? arrivedAtStoreAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAtCustomerAt;
  final DateTime? deliveredAt;

  const ActiveDeliveryMilestones({
    this.assignedAt,
    this.arrivedAtStoreAt,
    this.pickedUpAt,
    this.arrivedAtCustomerAt,
    this.deliveredAt,
  });

  factory ActiveDeliveryMilestones.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v != null ? DateTime.tryParse(v.toString()) : null;

    return ActiveDeliveryMilestones(
      assignedAt: parseDate(json['assignedAt']),
      arrivedAtStoreAt: parseDate(json['arrivedAtStoreAt']),
      pickedUpAt: parseDate(json['pickedUpAt']),
      arrivedAtCustomerAt: parseDate(json['arrivedAtCustomerAt']),
      deliveredAt: parseDate(json['deliveredAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'assignedAt': assignedAt?.toIso8601String(),
        'arrivedAtStoreAt': arrivedAtStoreAt?.toIso8601String(),
        'pickedUpAt': pickedUpAt?.toIso8601String(),
        'arrivedAtCustomerAt': arrivedAtCustomerAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };
}

class RiderActiveDeliveryDetail {
  final int orderId;
  final String orderNumber;
  final String fulfillmentStatus;
  final String orderStatus;
  final ActiveDeliveryStore store;
  final ActiveDeliveryCustomer customer;
  final List<ActiveDeliveryItem> items;
  final int totalItems;
  final int totalVolumeMl;
  final int deliveryFeePaisa;
  final int tipAmountPaisa;
  final int estimatedEarningsPaisa;
  final bool isAgeVerificationRequired;
  final String? specialInstructions;
  final ActiveDeliveryMilestones milestones;

  const RiderActiveDeliveryDetail({
    required this.orderId,
    required this.orderNumber,
    required this.fulfillmentStatus,
    required this.orderStatus,
    required this.store,
    required this.customer,
    required this.items,
    required this.totalItems,
    required this.totalVolumeMl,
    required this.deliveryFeePaisa,
    required this.tipAmountPaisa,
    required this.estimatedEarningsPaisa,
    required this.isAgeVerificationRequired,
    this.specialInstructions,
    required this.milestones,
  });

  String get formattedEarnings =>
      '₹${(estimatedEarningsPaisa / 100).toStringAsFixed(0)}';
  String get formattedDeliveryFee =>
      '₹${(deliveryFeePaisa / 100).toStringAsFixed(0)}';
  String get formattedTip =>
      '₹${(tipAmountPaisa / 100).toStringAsFixed(0)}';

  factory RiderActiveDeliveryDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RiderActiveDeliveryDetail(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      store: ActiveDeliveryStore.fromJson(
        json['store'] is Map
            ? Map<String, dynamic>.from(json['store'] as Map)
            : {},
      ),
      customer: ActiveDeliveryCustomer.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'] as Map)
            : {},
      ),
      items: rawItems
          .map((i) => ActiveDeliveryItem.fromJson(
              i is Map ? Map<String, dynamic>.from(i) : {}))
          .toList(),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalVolumeMl: (json['totalVolumeMl'] as num?)?.toInt() ?? 0,
      deliveryFeePaisa: (json['deliveryFeePaisa'] as num?)?.toInt() ?? 0,
      tipAmountPaisa: (json['tipAmountPaisa'] as num?)?.toInt() ?? 0,
      estimatedEarningsPaisa:
          (json['estimatedEarningsPaisa'] as num?)?.toInt() ?? 0,
      isAgeVerificationRequired:
          json['isAgeVerificationRequired'] as bool? ?? true,
      specialInstructions: json['specialInstructions']?.toString(),
      milestones: ActiveDeliveryMilestones.fromJson(
        json['milestones'] is Map
            ? Map<String, dynamic>.from(json['milestones'] as Map)
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'fulfillmentStatus': fulfillmentStatus,
        'orderStatus': orderStatus,
        'store': store.toJson(),
        'customer': customer.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'totalItems': totalItems,
        'totalVolumeMl': totalVolumeMl,
        'deliveryFeePaisa': deliveryFeePaisa,
        'tipAmountPaisa': tipAmountPaisa,
        'estimatedEarningsPaisa': estimatedEarningsPaisa,
        'isAgeVerificationRequired': isAgeVerificationRequired,
        'specialInstructions': specialInstructions,
        'milestones': milestones.toJson(),
      };
}

class RiderActiveStateResponse {
  final String riderStatus;
  final RiderStateType stateType;
  final RiderOfferPreview? activeOffer;
  final RiderActiveDeliveryDetail? activeDelivery;

  const RiderActiveStateResponse({
    required this.riderStatus,
    required this.stateType,
    this.activeOffer,
    this.activeDelivery,
  });

  bool get isIdle => stateType == RiderStateType.idle;
  bool get hasActiveOffer =>
      stateType == RiderStateType.activeOffer && activeOffer != null;
  bool get hasActiveDelivery =>
      stateType == RiderStateType.activeDelivery && activeDelivery != null;

  factory RiderActiveStateResponse.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['response'] is Map)
        ? Map<String, dynamic>.from(rawJson['response'] as Map)
        : rawJson;
    final rawType = json['stateType']?.toString();
    final type = RiderStateType.fromString(rawType);

    return RiderActiveStateResponse(
      riderStatus: json['riderStatus']?.toString() ?? 'OFFLINE',
      stateType: type,
      activeOffer: json['activeOffer'] is Map
          ? RiderOfferPreview.fromJson(
              Map<String, dynamic>.from(json['activeOffer'] as Map))
          : null,
      activeDelivery: json['activeDelivery'] is Map
          ? RiderActiveDeliveryDetail.fromJson(
              Map<String, dynamic>.from(json['activeDelivery'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderStatus': riderStatus,
        'stateType': stateType.value,
        'activeOffer': activeOffer?.toJson(),
        'activeDelivery': activeDelivery?.toJson(),
      };
}
