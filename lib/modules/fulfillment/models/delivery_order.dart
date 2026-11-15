import 'package:google_maps_flutter/google_maps_flutter.dart';

enum DeliveryFlowStep {
  offerReceived,
  headingToStore,
  arrivedAtStore,
  enterStoreOtp,
  pickupConfirmed,
  headingToCustomer,
  enterCustomerOtp,
  deliveryCompleted,
}

class DeliveryOrder {
  final int orderId;
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final LatLng storeLocation;
  final String storeDistanceText;
  final String storeTimeText;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final LatLng customerLocation;
  final String customerDistanceText;
  final String customerTimeText;
  final double totalDistanceKm;
  final int estimatedMinutes;
  final int orderValuePaisa;
  final int earningsPaisa;
  final int incentivePaisa;
  final String storeOtp;
  final String customerOtp;
  final DeliveryFlowStep currentStep;

  const DeliveryOrder({
    required this.orderId,
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    required this.storeLocation,
    required this.storeDistanceText,
    required this.storeTimeText,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerLocation,
    required this.customerDistanceText,
    required this.customerTimeText,
    required this.totalDistanceKm,
    required this.estimatedMinutes,
    required this.orderValuePaisa,
    required this.earningsPaisa,
    required this.incentivePaisa,
    this.storeOtp = '7349',
    this.customerOtp = '5826',
    this.currentStep = DeliveryFlowStep.offerReceived,
  });

  int get totalEarningsPaisa => earningsPaisa + incentivePaisa;

  String get formattedEarnings => '₹${(earningsPaisa / 100).toStringAsFixed(0)}';
  String get formattedIncentive => '₹${(incentivePaisa / 100).toStringAsFixed(0)}';
  String get formattedTotalEarnings => '₹${(totalEarningsPaisa / 100).toStringAsFixed(0)}';
  String get formattedOrderValue => '₹${(orderValuePaisa / 100).toStringAsFixed(0)}';

  DeliveryOrder copyWith({
    int? orderId,
    String? orderNumber,
    String? storeName,
    String? storeAddress,
    LatLng? storeLocation,
    String? storeDistanceText,
    String? storeTimeText,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    LatLng? customerLocation,
    String? customerDistanceText,
    String? customerTimeText,
    double? totalDistanceKm,
    int? estimatedMinutes,
    int? orderValuePaisa,
    int? earningsPaisa,
    int? incentivePaisa,
    String? storeOtp,
    String? customerOtp,
    DeliveryFlowStep? currentStep,
  }) {
    return DeliveryOrder(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storeLocation: storeLocation ?? this.storeLocation,
      storeDistanceText: storeDistanceText ?? this.storeDistanceText,
      storeTimeText: storeTimeText ?? this.storeTimeText,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLocation: customerLocation ?? this.customerLocation,
      customerDistanceText: customerDistanceText ?? this.customerDistanceText,
      customerTimeText: customerTimeText ?? this.customerTimeText,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      orderValuePaisa: orderValuePaisa ?? this.orderValuePaisa,
      earningsPaisa: earningsPaisa ?? this.earningsPaisa,
      incentivePaisa: incentivePaisa ?? this.incentivePaisa,
      storeOtp: storeOtp ?? this.storeOtp,
      customerOtp: customerOtp ?? this.customerOtp,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  // Default sample order matching the mock screen #ORD78216
  factory DeliveryOrder.sample() {
    return const DeliveryOrder(
      orderId: 78216,
      orderNumber: '#ORD78216',
      storeName: 'Royal Liquor Store',
      storeAddress: 'Lake Town, Kolkata',
      storeLocation: LatLng(22.5892, 88.4067),
      storeDistanceText: '2.6 km',
      storeTimeText: '6 min',
      customerName: 'Rahul Sharma',
      customerPhone: '+919876543210',
      customerAddress: 'GB Block, Sector V, Salt Lake, Kolkata',
      customerLocation: LatLng(22.5726, 88.4337),
      customerDistanceText: '4.2 km',
      customerTimeText: '9 min',
      totalDistanceKm: 6.8,
      estimatedMinutes: 15,
      orderValuePaisa: 243000, // ₹2,430
      earningsPaisa: 12000,    // ₹120
      incentivePaisa: 2000,    // ₹20
      storeOtp: '7349',
      customerOtp: '5826',
      currentStep: DeliveryFlowStep.offerReceived,
    );
  }

  /// Parses incoming RIDER_OFFER FCM notification payload into a DeliveryOrder
  factory DeliveryOrder.fromNotificationData(Map<String, dynamic> data) {
    final idStr = data['entityId'] ?? data['orderId'] ?? data['id'];
    final int id = int.tryParse(idStr?.toString() ?? '') ?? 78216;
    final String orderNum = data['orderNumber']?.toString() ??
        (idStr != null ? '#ORD$idStr' : '#ORD78216');

    final storeName = data['storeName']?.toString() ?? 'Royal Liquor Store';
    final storeAddress = data['storeAddress']?.toString() ?? 'Lake Town, Kolkata';
    final double storeLat = double.tryParse(data['storeLatitude']?.toString() ?? '') ?? 22.5892;
    final double storeLng = double.tryParse(data['storeLongitude']?.toString() ?? '') ?? 88.4067;
    final storeDist = data['storeDistance']?.toString() ??
        data['pickupDistance']?.toString() ??
        '2.6 km';
    final storeTime = data['storeTime']?.toString() ?? '6 min';

    final custName = data['customerName']?.toString() ?? 'Rahul Sharma';
    final custPhone = data['customerPhone']?.toString() ?? '+919876543210';
    final custAddress = data['customerAddress']?.toString() ??
        data['deliveryAddress']?.toString() ??
        'GB Block, Sector V, Salt Lake, Kolkata';
    final double custLat = double.tryParse(data['customerLatitude']?.toString() ?? '') ?? 22.5726;
    final double custLng = double.tryParse(data['customerLongitude']?.toString() ?? '') ?? 88.4337;
    final custDist = data['customerDistance']?.toString() ??
        data['deliveryDistance']?.toString() ??
        '4.2 km';
    final custTime = data['customerTime']?.toString() ?? '9 min';

    final double totalDist = double.tryParse(
            data['totalDistanceKm']?.toString() ?? data['distanceKm']?.toString() ?? '') ??
        6.8;
    final int estMins = int.tryParse(data['estimatedMinutes']?.toString() ?? '') ?? 15;
    final int orderVal = int.tryParse(
            data['orderValuePaisa']?.toString() ?? data['orderValue']?.toString() ?? '') ??
        243000;
    final int earnings = int.tryParse(
            data['earningsPaisa']?.toString() ?? data['deliveryFeePaisa']?.toString() ?? '') ??
        12000;
    final int incentive = int.tryParse(
            data['incentivePaisa']?.toString() ?? data['tipPaisa']?.toString() ?? '') ??
        2000;

    final storeOtp = data['storeOtp']?.toString() ?? '7349';
    final custOtp = data['customerOtp']?.toString() ?? '5826';

    return DeliveryOrder(
      orderId: id,
      orderNumber: orderNum.startsWith('#') ? orderNum : '#$orderNum',
      storeName: storeName,
      storeAddress: storeAddress,
      storeLocation: LatLng(storeLat, storeLng),
      storeDistanceText: storeDist,
      storeTimeText: storeTime,
      customerName: custName,
      customerPhone: custPhone,
      customerAddress: custAddress,
      customerLocation: LatLng(custLat, custLng),
      customerDistanceText: custDist,
      customerTimeText: custTime,
      totalDistanceKm: totalDist,
      estimatedMinutes: estMins,
      orderValuePaisa: orderVal,
      earningsPaisa: earnings,
      incentivePaisa: incentive,
      storeOtp: storeOtp,
      customerOtp: custOtp,
      currentStep: DeliveryFlowStep.offerReceived,
    );
  }
}

