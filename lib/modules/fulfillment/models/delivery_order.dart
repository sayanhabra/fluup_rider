import 'dart:math' as math;
import 'package:adm_rider/modules/fulfillment/models/rider_active_state_model.dart';
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
  final RiderActiveDeliveryDetail? activeDeliveryDetail;
  final int totalItems;
  final int totalVolumeMl;
  final List<ActiveDeliveryItem> items;

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
    this.activeDeliveryDetail,
    this.totalItems = 1,
    this.totalVolumeMl = 750,
    this.items = const [],
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
    RiderActiveDeliveryDetail? activeDeliveryDetail,
    int? totalItems,
    int? totalVolumeMl,
    List<ActiveDeliveryItem>? items,
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
      activeDeliveryDetail: activeDeliveryDetail ?? this.activeDeliveryDetail,
      totalItems: totalItems ?? this.totalItems,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      items: items ?? this.items,
    );
  }

  /// Maps an active offer preview from GET /rider/order-fulfillment/active
  factory DeliveryOrder.fromActiveOffer(RiderOfferPreview offer) {
    final double dist = offer.distanceKm ?? 3.5;
    return DeliveryOrder(
      orderId: offer.orderId,
      orderNumber: offer.orderNumber.startsWith('#')
          ? offer.orderNumber
          : '#${offer.orderNumber}',
      storeName: offer.storeName,
      storeAddress: offer.storeAddress,
      storeLocation: LatLng(offer.storeLatitude, offer.storeLongitude),
      storeDistanceText: '${dist.toStringAsFixed(1)} km',
      storeTimeText: '${offer.remainingSeconds}s remaining',
      customerName: 'Customer (${offer.deliveryArea})',
      customerPhone: '',
      customerAddress: offer.deliveryArea,
      customerLocation: LatLng(
        offer.storeLatitude + 0.015,
        offer.storeLongitude + 0.015,
      ),
      customerDistanceText: '${(dist * 0.7).toStringAsFixed(1)} km',
      customerTimeText: '12 min',
      totalDistanceKm: dist,
      estimatedMinutes: 15,
      orderValuePaisa: 0,
      earningsPaisa: offer.estimatedEarningsPaisa,
      incentivePaisa: 0,
      currentStep: DeliveryFlowStep.offerReceived,
      totalItems: offer.totalItems,
      totalVolumeMl: offer.totalVolumeMl,
    );
  }

  /// Maps ongoing active delivery details from GET /rider/order-fulfillment/active
  factory DeliveryOrder.fromActiveDelivery(RiderActiveDeliveryDetail detail) {
    final status = detail.fulfillmentStatus.toUpperCase();

    // Map fulfillmentStatus to DeliveryFlowStep
    DeliveryFlowStep step = DeliveryFlowStep.headingToStore;
    if (status.contains('ARRIVED_AT_STORE')) {
      step = DeliveryFlowStep.arrivedAtStore;
    } else if (status.contains('PICKED_UP')) {
      step = DeliveryFlowStep.pickupConfirmed;
    } else if (status.contains('OUT_FOR_DELIVERY')) {
      step = DeliveryFlowStep.headingToCustomer;
    } else if (status.contains('ARRIVED_AT_CUSTOMER')) {
      step = DeliveryFlowStep.enterCustomerOtp;
    } else if (status.contains('DELIVERED')) {
      step = DeliveryFlowStep.deliveryCompleted;
    }

    final double storeLat = detail.store.latitude != 0.0 ? detail.store.latitude : 22.5892;
    final double storeLng = detail.store.longitude != 0.0 ? detail.store.longitude : 88.4067;
    final double custLat = detail.customer.latitude != 0.0 ? detail.customer.latitude : 22.5726;
    final double custLng = detail.customer.longitude != 0.0 ? detail.customer.longitude : 88.4337;

    // Dynamically compute realistic road distance and travel time from coordinates
    final double dLat = (custLat - storeLat) * (math.pi / 180.0);
    final double dLng = (custLng - storeLng) * (math.pi / 180.0);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(storeLat * (math.pi / 180.0)) *
            math.cos(custLat * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double straightDistKm = 6371.0 * (2 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a)));
    final double roadDistKm = (straightDistKm * 1.25).clamp(0.5, 50.0);
    final int estMinutes = ((roadDistKm / 22.0) * 60).round().clamp(3, 90);

    return DeliveryOrder(
      orderId: detail.orderId,
      orderNumber: detail.orderNumber.startsWith('#')
          ? detail.orderNumber
          : '#${detail.orderNumber}',
      storeName: detail.store.name,
      storeAddress: detail.store.address,
      storeLocation: LatLng(storeLat, storeLng),
      storeDistanceText: '${(roadDistKm * 0.4).clamp(0.4, 15.0).toStringAsFixed(1)} km',
      storeTimeText: '${((roadDistKm * 0.4 / 22.0) * 60).round().clamp(2, 45)} min',
      customerName: detail.customer.name,
      customerPhone: detail.customer.phone,
      customerAddress: detail.customer.pincode.isNotEmpty
          ? '${detail.customer.deliveryAddress}, ${detail.customer.pincode}'
          : detail.customer.deliveryAddress,
      customerLocation: LatLng(custLat, custLng),
      customerDistanceText: '${roadDistKm.toStringAsFixed(1)} km',
      customerTimeText: '$estMinutes min',
      totalDistanceKm: double.parse(roadDistKm.toStringAsFixed(1)),
      estimatedMinutes: estMinutes,
      orderValuePaisa: 0,
      earningsPaisa: detail.deliveryFeePaisa,
      incentivePaisa: detail.tipAmountPaisa,
      currentStep: step,
      activeDeliveryDetail: detail,
      totalItems: detail.totalItems,
      totalVolumeMl: detail.totalVolumeMl,
      items: detail.items,
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

