import 'dart:math' as math;
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_marker_helper.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_route_helper.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_navigation_model.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/rider_navigation_provider.dart';
import 'package:adm_rider/modules/fulfillment/widgets/custom_numeric_keypad.dart';
import 'package:adm_rider/modules/fulfillment/widgets/otp_code_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  ConsumerState<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  String _enteredOtp = '';
  late final TextEditingController _otpTextController;
  late final FocusNode _otpFocusNode;
  bool _isAgeVerified = true;
  BitmapDescriptor? _twoWheelerIcon;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _enteredOtp = '';
    _otpTextController = TextEditingController();
    _otpFocusNode = FocusNode();
    _initTwoWheelerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(fulfillmentProvider.notifier).checkAndSyncActiveState();
      await _ensureLocationAndInitNavigation();
    });
  }

  @override
  void dispose() {
    _otpTextController.dispose();
    _otpFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _resetOtp() {
    setState(() {
      _enteredOtp = '';
      _otpTextController.clear();
    });
  }

  Future<void> _ensureLocationAndInitNavigation() async {
    var riderLoc = ref.read(riderLiveLocationProvider);
    if (riderLoc == null) {
      final locResult = await LocationHelper.instance.getLocationWithFastFallback();
      if (locResult.isSuccess && locResult.position != null) {
        riderLoc = LatLng(locResult.position!.latitude, locResult.position!.longitude);
        ref.read(riderLiveLocationProvider.notifier).updateLocation(riderLoc);
      }
    }
    if (!mounted) return;
    _initNavigationForCurrentStep(riderLoc: riderLoc);
  }

  void _initNavigationForCurrentStep({LatLng? riderLoc}) {
    final order = ref.read(fulfillmentProvider).activeOrder ?? DeliveryOrder.sample();
    final effectiveRider = riderLoc ?? ref.read(riderLiveLocationProvider);

    final isCustomerLeg = order.currentStep == DeliveryFlowStep.headingToCustomer ||
        order.currentStep == DeliveryFlowStep.enterCustomerOtp;
    final leg = isCustomerLeg ? NavigationLegEnum.delivery : NavigationLegEnum.pickup;

    final double effectiveRiderLat = effectiveRider?.latitude ?? order.storeLocation.latitude;
    final double effectiveRiderLng = effectiveRider?.longitude ?? order.storeLocation.longitude;

    ref.read(riderNavigationProvider.notifier).fetchNavigation(
          order.orderId,
          leg: leg,
          riderLat: effectiveRiderLat,
          riderLng: effectiveRiderLng,
          storeLocation: order.storeLocation,
          customerLocation: order.customerLocation,
        );
  }

  void _fitMapToRoute(DeliveryOrder order, List<LatLng> points, LatLng? riderPos) {
    if (_mapController == null) return;
    final isCustomer = order.currentStep == DeliveryFlowStep.headingToCustomer ||
        order.currentStep == DeliveryFlowStep.enterCustomerOtp;
    final destination = isCustomer ? order.customerLocation : order.storeLocation;
    final allPoints = <LatLng>[
      ?riderPos,
      destination,
      ...points,
    ];
    final bounds = TwoWheelerRouteHelper.calculateBounds(allPoints, paddingRatio: 0.002);
    if (bounds != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }
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

  void _onDigitPressed(String digit, int maxLen) {
    if (_enteredOtp.length < maxLen) {
      setState(() {
        _enteredOtp += digit;
        _otpTextController.text = _enteredOtp;
        _otpTextController.selection = TextSelection.collapsed(offset: _enteredOtp.length);
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredOtp.isNotEmpty) {
      setState(() {
        _enteredOtp = _enteredOtp.substring(0, _enteredOtp.length - 1);
        _otpTextController.text = _enteredOtp;
        _otpTextController.selection = TextSelection.collapsed(offset: _enteredOtp.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LatLng?>(riderLiveLocationProvider, (prev, next) {
      if (next != null && next != prev && _mapController != null) {
        if (prev == null) {
          _initNavigationForCurrentStep(riderLoc: next);
        }
        final order = ref.read(fulfillmentProvider).activeOrder;
        final nav = ref.read(riderNavigationProvider);
        if (order != null) {
          _fitMapToRoute(order, nav.routePoints, next);
        } else {
          _mapController!.animateCamera(CameraUpdate.newLatLng(next));
        }
      }
    });

    ref.listen<RiderNavigationState>(riderNavigationProvider, (prev, next) {
      if (next.routePoints.isNotEmpty && next.routePoints != prev?.routePoints && _mapController != null) {
        final order = ref.read(fulfillmentProvider).activeOrder;
        if (order != null) {
          final riderPos = ref.read(riderLiveLocationProvider);
          _fitMapToRoute(order, next.routePoints, riderPos);
        }
      }
    });

    ref.listen<FulfillmentState>(fulfillmentProvider, (prev, next) {
      if (prev?.activeOrder?.currentStep != next.activeOrder?.currentStep) {
        final newStep = next.activeOrder?.currentStep;
        if (newStep == DeliveryFlowStep.enterStoreOtp ||
            newStep == DeliveryFlowStep.enterCustomerOtp) {
          _resetOtp();
        }
      }
    });

    final fulfillment = ref.watch(fulfillmentProvider);
    final order = fulfillment.activeOrder ?? DeliveryOrder.sample();
    final step = order.currentStep;

    return switch (step) {
      DeliveryFlowStep.offerReceived => const SizedBox.shrink(),
      DeliveryFlowStep.headingToStore => _buildHeadingToStore(context, order),
      DeliveryFlowStep.arrivedAtStore => _buildHeadingToStore(context, order),
      DeliveryFlowStep.enterStoreOtp => _buildEnterStoreOtp(context, order),
      DeliveryFlowStep.pickupConfirmed => _buildHeadingToCustomer(context, order),
      DeliveryFlowStep.headingToCustomer => _buildHeadingToCustomer(context, order),
      DeliveryFlowStep.enterCustomerOtp => _buildEnterCustomerOtp(context, order),
      DeliveryFlowStep.deliveryCompleted => _buildDeliveryCompleted(context, order),
    };
  }

  // ============================================================
  // 1. HEADING TO STORE (Screen 5)
  // ============================================================
  Widget _buildHeadingToStore(BuildContext context, DeliveryOrder order) {
    final navState = ref.watch(riderNavigationProvider);
    final fulfillment = ref.watch(fulfillmentProvider);
    final riderPos = ref.watch(riderLiveLocationProvider);
    final polylinePoints = navState.routePoints.isNotEmpty
        ? navState.routePoints
        : (riderPos != null
            ? TwoWheelerRouteHelper.generateTwoWheelerRoute(
                origin: riderPos,
                destination: order.storeLocation,
              )
            : <LatLng>[]);

    final double distToStoreMeters = riderPos != null
        ? TwoWheelerRouteHelper.calculateDistanceMeters(
            riderPos,
            order.storeLocation,
          )
        : 999.0;
    final bool isWithin30m = distToStoreMeters <= 30.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          children: [
            Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Heading to Store',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map View with route to Store
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: riderPos ?? order.storeLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToRoute(order, polylinePoints, riderPos);
            },
            markers: {
              Marker(
                markerId: const MarkerId('store'),
                position: order.storeLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: order.storeName,
                  snippet: order.storeAddress,
                ),
              ),
              if (riderPos != null)
                Marker(
                  markerId: const MarkerId('rider_bike'),
                  position: riderPos,
                  icon: _twoWheelerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: const InfoWindow(title: 'You (Rider)'),
                ),
            },
            polylines: polylinePoints.length >= 2 ? {
              TwoWheelerRouteHelper.createTwoWheelerPolyline(
                polylineId: 'toStoreRoute',
                points: polylinePoints,
                color: Colors.blue.shade600,
                width: 6,
              ),
            } : const {},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top Turn-by-Turn Navigation HUD (Clean, no tabs)
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _buildNavigationHud(context, order, navState),
          ),

          // Bottom Store Card (Clean UI: Info icon for details, No Navigate button, Arrived at Store when within 30m)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Brand.redLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront, color: Brand.red, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.storeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.storeAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.storeDistanceText} • ${order.storeTimeText}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Order Details',
                        icon: const Icon(Icons.info_outline, color: Brand.red, size: 24),
                        onPressed: () => _showOrderDetailsModal(context, order),
                      ),
                    ],
                  ),
                  if (isWithin30m) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: fulfillment.isLoading
                            ? null
                            : () async {
                                setState(() => _enteredOtp = '');
                                await ref.read(fulfillmentProvider.notifier).confirmArrivedAtStore(
                                      order.orderId,
                                      riderPos?.latitude ?? order.storeLocation.latitude,
                                      riderPos?.longitude ?? order.storeLocation.longitude,
                                    );
                              },
                        icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                        label: fulfillment.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Arrived at Store',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Brand.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onDoubleTap: () {
                        ref.read(riderLiveLocationProvider.notifier).updateLocation(
                              order.storeLocation,
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 18, color: Brand.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${distToStoreMeters >= 1000 ? '${(distToStoreMeters / 1000).toStringAsFixed(1)} km' : '${distToStoreMeters.round()} m'} to store • Arrived button appears within 30m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. ARRIVED AT STORE? (Screen 6)
  // ============================================================
  Widget _buildArrivedAtStorePrompt(BuildContext context, DeliveryOrder order) {
    final fulfillment = ref.watch(fulfillmentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(fulfillmentProvider.notifier).acceptOffer(order.orderId);
          },
        ),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              // Store Illustration
              Container(
                width: 220,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Store canopy / facade
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Brand.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LIQUOR STORE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Bottles display window
                        Container(
                          width: 140,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Icon(Icons.wine_bar, color: Brand.amber, size: 28),
                              Icon(Icons.local_drink, color: Brand.red, size: 28),
                              Icon(Icons.liquor, color: Brand.deepPurple, size: 28),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Brand.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Arrived at Store?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Confirm your arrival at ${order.storeName} to start the pickup.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),

              // Confirm Arrived Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fulfillment.isLoading
                      ? null
                      : () {
                          setState(() => _enteredOtp = '');
                          ref.read(fulfillmentProvider.notifier).confirmArrivedAtStore(
                                order.orderId,
                                order.storeLocation.latitude,
                                order.storeLocation.longitude,
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: fulfillment.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Confirm Arrived',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 3. ENTER STORE OTP (Screen 7)
  // ============================================================
  Widget _buildEnterStoreOtp(BuildContext context, DeliveryOrder order) {
    final fulfillment = ref.watch(fulfillmentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(fulfillmentProvider.notifier).proceedToArrivedAtStore();
          },
        ),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            const SizedBox(height: 20),
            const Text(
              'Enter Store OTP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Get the OTP from the store partner and confirm pickup.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 32),

            // 4 OTP Boxes with tap to focus
            OtpCodeBoxes(
              otp: _enteredOtp,
              length: 4,
              onTap: () => _otpFocusNode.requestFocus(),
            ),

            // Invisible TextField to receive software/hardware keyboard input seamlessly
            SizedBox(
              width: 0,
              height: 0,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otpTextController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _enteredOtp = val;
                    });
                  },
                ),
              ),
            ),

            if (_enteredOtp.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _resetOtp,
                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                label: const Text('Clear', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            ],

            if (fulfillment.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                fulfillment.errorMessage!,
                style: const TextStyle(color: Brand.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),

            // Confirm Pickup Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_enteredOtp.length == 4 && !fulfillment.isLoading)
                      ? () async {
                          final success = await ref
                              .read(fulfillmentProvider.notifier)
                              .verifyStoreOtp(
                                orderId: order.orderId,
                                otp: _enteredOtp,
                                lat: order.storeLocation.latitude,
                                lng: order.storeLocation.longitude,
                              );
                          if (success) {
                            _resetOtp();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.red,
                    disabledBackgroundColor: Brand.red.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: fulfillment.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Confirm Pickup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Custom in-app numeric pad
            CustomNumericKeypad(
              onDigitPressed: (digit) => _onDigitPressed(digit, 4),
              onBackspacePressed: _onBackspacePressed,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // 4. PICKUP CONFIRMED! (Screen 8)
  // ============================================================
  Widget _buildPickupConfirmed(BuildContext context, DeliveryOrder order) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(fulfillmentProvider.notifier).proceedToEnterStoreOtp();
          },
        ),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              // Big green checkmark
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Brand.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Pickup Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You have successfully picked up\nthe order from the store.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),

              // Navigate to Customer Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _enteredOtp = '');
                    ref.read(fulfillmentProvider.notifier).proceedToHeadingToCustomer();
                    final riderLoc = ref.read(riderLiveLocationProvider);
                    final effectiveRiderLat = riderLoc?.latitude ?? order.storeLocation.latitude;
                    final effectiveRiderLng = riderLoc?.longitude ?? order.storeLocation.longitude;
                    ref.read(riderNavigationProvider.notifier).changeLeg(
                          order.orderId,
                          NavigationLegEnum.delivery,
                          riderLat: effectiveRiderLat,
                          riderLng: effectiveRiderLng,
                          storeLocation: order.storeLocation,
                          customerLocation: order.customerLocation,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Navigate to Customer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 5. HEADING TO CUSTOMER (Clean UI: Info icon for details, No Navigate button, Arrived at Delivery Location when within 30m)
  // ============================================================
  Widget _buildHeadingToCustomer(BuildContext context, DeliveryOrder order) {
    final navState = ref.watch(riderNavigationProvider);
    final fulfillment = ref.watch(fulfillmentProvider);
    final riderPos = ref.watch(riderLiveLocationProvider);
    final effectiveRider = riderPos ?? order.storeLocation;
    final polylinePoints = navState.routePoints.isNotEmpty
        ? navState.routePoints
        : TwoWheelerRouteHelper.generateTwoWheelerRoute(
            origin: effectiveRider,
            destination: order.customerLocation,
          );

    final double distToCustomerMeters = riderPos != null
        ? TwoWheelerRouteHelper.calculateDistanceMeters(
            riderPos,
            order.customerLocation,
          )
        : 999.0;
    final bool isWithin30m = distToCustomerMeters <= 30.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          children: [
            Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Heading to Customer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map to customer location
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: riderPos ?? order.customerLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToRoute(order, polylinePoints, riderPos);
            },
            markers: {
              Marker(
                markerId: const MarkerId('customer'),
                position: order.customerLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: order.customerName,
                  snippet: order.customerAddress,
                ),
              ),
              if (riderPos != null)
                Marker(
                  markerId: const MarkerId('rider_bike'),
                  position: riderPos,
                  icon: _twoWheelerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: const InfoWindow(title: 'You (Rider)'),
                ),
            },
            polylines: polylinePoints.length >= 2 ? {
              TwoWheelerRouteHelper.createTwoWheelerPolyline(
                polylineId: 'toCustomerRoute',
                points: polylinePoints,
                color: Brand.red,
                width: 6,
              ),
            } : const {},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top Turn-by-Turn Navigation HUD (Clean, no tabs)
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _buildNavigationHud(context, order, navState),
          ),

          // Bottom Customer Card (Clean UI: Info icon for details, No Navigate button, Arrived at Delivery Location when within 30m)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Brand.redLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on, color: Brand.red, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerAddress.split(',').first,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.customerAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.customerDistanceText} • ${order.customerTimeText}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Order Details',
                        icon: const Icon(Icons.info_outline, color: Brand.red, size: 24),
                        onPressed: () => _showOrderDetailsModal(context, order),
                      ),
                    ],
                  ),
                  if (isWithin30m) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: fulfillment.isLoading
                            ? null
                            : () async {
                                setState(() => _enteredOtp = '');
                                await ref.read(fulfillmentProvider.notifier).recordArrivedAtCustomer(
                                      order.orderId,
                                      riderPos?.latitude ?? order.customerLocation.latitude,
                                      riderPos?.longitude ?? order.customerLocation.longitude,
                                    );
                              },
                        icon: const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 20),
                        label: fulfillment.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Arrived at Delivery Location',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Brand.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onDoubleTap: () {
                        ref.read(riderLiveLocationProvider.notifier).updateLocation(
                              order.customerLocation,
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 18, color: Brand.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${distToCustomerMeters >= 1000 ? '${(distToCustomerMeters / 1000).toStringAsFixed(1)} km' : '${distToCustomerMeters.round()} m'} to customer • Arrived button appears within 30m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 6. ENTER CUSTOMER OTP (Screen 10)
  // ============================================================
  Widget _buildEnterCustomerOtp(BuildContext context, DeliveryOrder order) {
    final fulfillment = ref.watch(fulfillmentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(fulfillmentProvider.notifier).proceedToHeadingToCustomer();
          },
        ),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            const SizedBox(height: 20),
            const Text(
              'Enter Customer OTP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ask the customer for the OTP to confirm delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 28),

            // 4 OTP Boxes with tap to focus
            OtpCodeBoxes(
              otp: _enteredOtp,
              length: 4,
              onTap: () => _otpFocusNode.requestFocus(),
            ),

            // Invisible TextField to receive software/hardware keyboard input seamlessly
            SizedBox(
              width: 0,
              height: 0,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otpTextController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _enteredOtp = val;
                    });
                  },
                ),
              ),
            ),

            if (_enteredOtp.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _resetOtp,
                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                label: const Text('Clear', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            ],

            if (fulfillment.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                fulfillment.errorMessage!,
                style: const TextStyle(color: Brand.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 16),

            // 21+ Drinking Age Checkbox / Confirmation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Checkbox(
                    value: _isAgeVerified,
                    activeColor: Brand.red,
                    onChanged: (val) {
                      setState(() => _isAgeVerified = val ?? true);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Customer verified 21+ legal drinking age',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Confirm Delivery Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_enteredOtp.length == 4 && _isAgeVerified && !fulfillment.isLoading)
                      ? () async {
                          final success = await ref
                              .read(fulfillmentProvider.notifier)
                              .completeCustomerDelivery(
                                orderId: order.orderId,
                                otp: _enteredOtp,
                                isAgeVerified: _isAgeVerified,
                              );
                          if (success && context.mounted) {
                            _resetOtp();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delivery completed successfully!'),
                                backgroundColor: Brand.green,
                              ),
                            );
                            ref.read(fulfillmentProvider.notifier).finishAndClearOrder();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.red,
                    disabledBackgroundColor: Brand.red.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: fulfillment.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Confirm Delivery',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Custom in-app numeric pad
            CustomNumericKeypad(
              onDigitPressed: (digit) => _onDigitPressed(digit, 4),
              onBackspacePressed: _onBackspacePressed,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // 7. DELIVERY COMPLETED! (Screen 11)
  // ============================================================
  Widget _buildDeliveryCompleted(BuildContext context, DeliveryOrder order) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(fulfillmentProvider.notifier).finishAndClearOrder();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          'Order ${order.orderNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // Circular festive celebratory badge (Screen 11)
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _FestiveRaysPainter(),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Brand.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Delivery Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),

              // Earnings Breakdown Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Earnings', style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
                        Text(order.formattedEarnings, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Incentive', style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
                        Text(order.formattedIncentive, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Brand.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Earned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text(order.formattedTotalEarnings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Brand.red)),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(fulfillmentProvider.notifier).finishAndClearOrder();
                    Navigator.of(context).maybePop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TURN-BY-TURN NAVIGATION HUD & ROUTE CONTROLS
  // ============================================================

  Widget _buildNavigationHud(
    BuildContext context,
    DeliveryOrder order,
    RiderNavigationState navState,
  ) {
    final currentStep = navState.currentStep;
    final totalSteps = navState.navigation?.route.steps.length ?? 0;
    final stepNum = (navState.currentStepIndex + 1);

    return InkWell(
      onTap: () => _showManeuverStepsModal(context, navState),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Maneuver Turn Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                currentStep?.getManeuverIcon() ?? Icons.straight_rounded,
                color: const Color(0xFF38BDF8),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            // Maneuver instruction and distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        currentStep != null && currentStep.distanceText.isNotEmpty
                            ? 'In ${currentStep.distanceText}'
                            : 'Route Navigation',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalSteps > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$stepNum of $totalSteps',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentStep?.cleanInstruction.isNotEmpty == true
                        ? currentStep!.cleanInstruction
                        : 'Proceed along two-wheeler route',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ETA & distance summary pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    navState.totalDurationText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  navState.totalDistanceText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegSelectorChips(
    BuildContext context,
    DeliveryOrder order,
    RiderNavigationState navState,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NavigationLegEnum.values.map((leg) {
          final isSelected = navState.selectedLeg == leg;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                leg.icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              label: Text(
                leg.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              selected: isSelected,
              backgroundColor: Colors.white,
              selectedColor: Brand.red,
              showCheckmark: false,
              elevation: 2,
              pressElevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Brand.red : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              onSelected: (_) {
                final riderLoc = ref.read(riderLiveLocationProvider);
                final effectiveRiderLat = riderLoc?.latitude ?? order.storeLocation.latitude;
                final effectiveRiderLng = riderLoc?.longitude ?? order.storeLocation.longitude;
                ref.read(riderNavigationProvider.notifier).changeLeg(
                      order.orderId,
                      leg,
                      riderLat: effectiveRiderLat,
                      riderLng: effectiveRiderLng,
                      storeLocation: order.storeLocation,
                      customerLocation: order.customerLocation,
                    );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOrderDetailsModal(BuildContext context, DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Earnings Summary Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expected Payout',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.formattedTotalEarnings,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Brand.red,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Trip: ${order.formattedEarnings}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  if (order.incentivePaisa > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Tip: ${order.formattedIncentive}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Store Section
                        const Text(
                          'Store Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.storefront, color: Colors.blue.shade700, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.storeName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.storeAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (order.activeDeliveryDetail?.store.phone?.isNotEmpty == true) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.activeDeliveryDetail!.store.phone!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Customer Section
                        const Text(
                          'Delivery Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Brand.redLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.location_on, color: Brand.red, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.customerAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (order.customerPhone.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.customerPhone,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Package Items Section
                        Text(
                          'Package Items (${order.totalItems} items • ${order.totalVolumeMl} ml)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order.items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF64748B)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Standard Parcel (${order.totalItems} item)',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: order.items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = order.items[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${item.quantity}x',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Brand.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            if (item.packageSize != null && item.packageSize!.isNotEmpty)
                                              Text(
                                                'Size: ${item.packageSize}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManeuverStepsModal(
    BuildContext context,
    RiderNavigationState navState,
  ) {
    final steps = navState.navigation?.route.steps ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Turn-by-Turn Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${navState.selectedLeg.label} • ${navState.totalDistanceText} (${navState.totalDurationText})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              if (navState.navigation?.routeWarning.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          navState.navigation!.routeWarning,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: steps.isEmpty
                    ? const Center(
                        child: Text(
                          'No step maneuvers available',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: steps.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          final isCurrent = index == navState.currentStepIndex;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrent ? Brand.red : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                step.getManeuverIcon(),
                                color: isCurrent ? Colors.white : const Color(0xFF334155),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              step.cleanInstruction,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: Text(
                              '${step.distanceText} • ${step.durationText}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            trailing: isCurrent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Brand.redLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: Brand.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              ref.read(riderNavigationProvider.notifier).selectStep(index);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
    );
  }

  Widget _buildOrderItemsSummary(DeliveryOrder order) {
    if (order.items.isEmpty && order.totalItems <= 1) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📦 Package Contents (${order.totalItems} items • ${order.totalVolumeMl} ml)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...order.items.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• ${item.productName}${item.packageSize != null ? " (${item.packageSize})" : ""} x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Festive celebratory rays surrounding the checkmark in Screen 11
class _FestiveRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const rayColors = [
      Color(0xFFE53935), // Red
      Color(0xFFFF9800), // Orange
      Color(0xFF4CAF50), // Green
      Color(0xFF00BCD4), // Cyan
      Color(0xFF2196F3), // Blue
      Color(0xFF9C27B0), // Purple
      Color(0xFFE91E63), // Pink
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF4ADE80), // Neon green
      Color(0xFFFF5722), // Deep orange
      Color(0xFF3B82F6), // Indigo
      Color(0xFF10B981), // Emerald
    ];

    for (int i = 0; i < rayColors.length; i++) {
      final angle = (i * 2 * math.pi / rayColors.length) - (math.pi / 2);
      final p1 = Offset(
        center.dx + (radius - 16) * math.cos(angle),
        center.dy + (radius - 16) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final paint = Paint()
        ..color = rayColors[i]
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
