import 'dart:async';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/notification_sound_helper.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_marker_helper.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_route_helper.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_navigation_model.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/rider_navigation_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/active_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewOrderRequestModal extends ConsumerStatefulWidget {
  final DeliveryOrder order;
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const NewOrderRequestModal({
    super.key,
    required this.order,
    this.onAccepted,
    this.onRejected,
  });

  @override
  ConsumerState<NewOrderRequestModal> createState() => _NewOrderRequestModalState();
}

class _NewOrderRequestModalState extends ConsumerState<NewOrderRequestModal> {
  Timer? _countdownTimer;
  int _secondsRemaining = 45;
  BitmapDescriptor? _twoWheelerIcon;
  GoogleMapController? _mapController;
  LatLng? _riderLocation;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _initTwoWheelerIcon();
    _riderLocation = ref.read(riderLiveLocationProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOfferNavigation();
    });
  }

  Future<void> _initTwoWheelerIcon() async {
    try {
      final icon = await TwoWheelerMarkerHelper.instance.getTwoWheelerMarker();
      if (mounted) {
        setState(() {
          _twoWheelerIcon = icon;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOfferNavigation() async {
    ref.read(riderNavigationProvider.notifier).clear();
    var riderPos = ref.read(riderLiveLocationProvider);
    if (riderPos == null) {
      final result = await LocationHelper.instance.getLocationWithFallback();
      if (result.isSuccess && result.position != null) {
        riderPos = LatLng(result.position!.latitude, result.position!.longitude);
        ref.read(riderLiveLocationProvider.notifier).updateLocation(riderPos);
      }
    }
    if (!mounted) return;
    setState(() => _riderLocation = riderPos);

    final effectiveRider = riderPos ??
        LatLng(
          widget.order.storeLocation.latitude - 0.012,
          widget.order.storeLocation.longitude - 0.008,
        );

    ref.read(riderNavigationProvider.notifier).fetchNavigation(
          widget.order.orderId,
          leg: NavigationLegEnum.full,
          riderLat: effectiveRider.latitude,
          riderLng: effectiveRider.longitude,
          storeLocation: widget.order.storeLocation,
          customerLocation: widget.order.customerLocation,
        );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _handleReject(reason: 'Offer expired (45s)');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    NotificationSoundHelper.instance.stop();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    _countdownTimer?.cancel();
    NotificationSoundHelper.instance.stop();

    if (widget.onAccepted != null) {
      widget.onAccepted!();
      return;
    }

    Navigator.of(context).pop();
    await ref
        .read(fulfillmentProvider.notifier)
        .acceptOffer(widget.order.orderId);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
      );
    }
  }

  Future<void> _handleReject({String? reason}) async {
    _countdownTimer?.cancel();
    NotificationSoundHelper.instance.stop();

    if (widget.onRejected != null) {
      widget.onRejected!();
      return;
    }

    await ref
        .read(fulfillmentProvider.notifier)
        .rejectOffer(widget.order.orderId, reason);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Set<Marker> _buildMarkers(LatLng? riderPos) {
    final markers = <Marker>{
      if (riderPos != null) Marker(
        markerId: const MarkerId('rider_bike'),
        position: riderPos,
        icon: _twoWheelerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'You (Rider)'),
      ),
      Marker(
        markerId: const MarkerId('store'),
        position: widget.order.storeLocation,
        infoWindow: InfoWindow(
          title: widget.order.storeName,
          snippet: 'Pickup: ${widget.order.storeDistanceText} (${widget.order.storeTimeText})',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: widget.order.customerLocation,
        infoWindow: InfoWindow(
          title: 'Delivery Location',
          snippet: '${widget.order.customerDistanceText} (${widget.order.customerTimeText})',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
    return markers;
  }

  Set<Polyline> _buildPolylines(LatLng? riderPos, RiderNavigationState navState) {
    final effectiveRider = riderPos ??
        LatLng(
          widget.order.storeLocation.latitude - 0.012,
          widget.order.storeLocation.longitude - 0.008,
        );

    final points = navState.routePoints.isNotEmpty
        ? navState.routePoints
        : TwoWheelerRouteHelper.generateTwoWheelerRoute(
            origin: effectiveRider,
            waypoints: [widget.order.storeLocation],
            destination: widget.order.customerLocation,
          );

    return {
      TwoWheelerRouteHelper.createTwoWheelerPolyline(
        polylineId: 'offerTwoWheelerRoute',
        points: points,
        color: Brand.red,
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    // ignore: unused_local_variable
    final fulfillment = ref.watch(fulfillmentProvider);
    final navState = ref.watch(riderNavigationProvider);
    final liveLocation = ref.watch(riderLiveLocationProvider);
    final riderPos = liveLocation ?? _riderLocation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _handleReject,
        ),
        title: const Text(
          'New Order Request',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Brand.redLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Brand.redBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Brand.red),
                const SizedBox(width: 4),
                Text(
                  '${_secondsRemaining}s',
                  style: const TextStyle(
                    color: Brand.red,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route Map with Store & Delivery Callouts
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: order.storeLocation,
                      zoom: 13.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      final bounds = TwoWheelerRouteHelper.calculateBounds([
                        if (riderPos != null) riderPos,
                        order.storeLocation,
                        order.customerLocation,
                      ]);
                      if (bounds != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(bounds, 50),
                        );
                      }
                    },
                    markers: _buildMarkers(riderPos),
                    polylines: _buildPolylines(riderPos, navState),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),

                  // Store Callout Tag
                  Positioned(
                    left: 20,
                    top: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Brand.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.store, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Store (Pickup)\n${order.storeDistanceText} (${order.storeTimeText})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delivery Location Callout Tag
                  Positioned(
                    right: 20,
                    top: 100,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Delivery Location\n${order.customerDistanceText} (${order.customerTimeText})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Order Details Sheet
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order # and Est. Earnings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Brand.redLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Brand.red, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Order ${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order.formattedTotalEarnings,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            'Est. Earnings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Pickup details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, size: 18, color: Brand.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup: ${order.storeName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.storeAddress,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Deliver to details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFF1E293B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deliver to: ${order.customerAddress.split(',').first}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.customerAddress,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Metrics summary: Total Distance | Est. Time | Order Value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Distance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('${order.totalDistanceKm} km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      Column(
                        children: [
                          const Text('Est. Time', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('${order.estimatedMinutes} min', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      Column(
                        children: [
                          const Text('Order Value', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(order.formattedOrderValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions: Reject and Accept Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: fulfillment.isLoading ? null : _handleReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Brand.red,
                            side: const BorderSide(color: Brand.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: fulfillment.isLoading ? null : _handleAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Brand.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: fulfillment.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Accept (${_secondsRemaining}s)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
