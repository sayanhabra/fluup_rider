import 'dart:math' as math;
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_marker_helper.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/widgets/custom_numeric_keypad.dart';
import 'package:adm_rider/modules/fulfillment/widgets/otp_code_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  ConsumerState<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  String _enteredOtp = '';
  bool _isAgeVerified = true;
  BitmapDescriptor? _twoWheelerIcon;

  @override
  void initState() {
    super.initState();
    _initTwoWheelerIcon();
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
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredOtp.isNotEmpty) {
      setState(() {
        _enteredOtp = _enteredOtp.substring(0, _enteredOtp.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fulfillment = ref.watch(fulfillmentProvider);
    final order = fulfillment.activeOrder ?? DeliveryOrder.sample();
    final step = order.currentStep;

    return switch (step) {
      DeliveryFlowStep.offerReceived => const SizedBox.shrink(),
      DeliveryFlowStep.headingToStore => _buildHeadingToStore(context, order),
      DeliveryFlowStep.arrivedAtStore => _buildArrivedAtStorePrompt(context, order),
      DeliveryFlowStep.enterStoreOtp => _buildEnterStoreOtp(context, order),
      DeliveryFlowStep.pickupConfirmed => _buildPickupConfirmed(context, order),
      DeliveryFlowStep.headingToCustomer => _buildHeadingToCustomer(context, order),
      DeliveryFlowStep.enterCustomerOtp => _buildEnterCustomerOtp(context, order),
      DeliveryFlowStep.deliveryCompleted => _buildDeliveryCompleted(context, order),
    };
  }

  // ============================================================
  // 1. HEADING TO STORE (Screen 5)
  // ============================================================
  Widget _buildHeadingToStore(BuildContext context, DeliveryOrder order) {
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
              target: order.storeLocation,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('store'),
                position: order.storeLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: order.storeName),
              ),
              Marker(
                markerId: const MarkerId('rider_bike'),
                position: ref.watch(riderLiveLocationProvider) ?? const LatLng(22.5820, 88.3980),
                icon: _twoWheelerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                anchor: const Offset(0.5, 0.5),
                infoWindow: const InfoWindow(title: 'You (Rider)'),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('toStore'),
                color: Colors.blue.shade600,
                width: 5,
                points: [
                  const LatLng(22.5820, 88.3980),
                  order.storeLocation,
                ],
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Bottom Store Card & Navigation Action
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(fulfillmentProvider.notifier).proceedToArrivedAtStore();
                          },
                          icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Brand.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          setState(() => _enteredOtp = order.storeOtp);
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

            // 4 OTP Boxes
            OtpCodeBoxes(otp: _enteredOtp, length: 4),

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
                      ? () {
                          ref.read(fulfillmentProvider.notifier).verifyStoreOtp(
                                orderId: order.orderId,
                                otp: _enteredOtp,
                                lat: order.storeLocation.latitude,
                                lng: order.storeLocation.longitude,
                              );
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

            const Spacer(),

            // Custom in-app numeric pad
            CustomNumericKeypad(
              onDigitPressed: (digit) => _onDigitPressed(digit, 4),
              onBackspacePressed: _onBackspacePressed,
            ),
            const SizedBox(height: 12),
          ],
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
                    setState(() => _enteredOtp = order.customerOtp);
                    ref.read(fulfillmentProvider.notifier).proceedToHeadingToCustomer();
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
  // 5. HEADING TO CUSTOMER (Screen 9)
  // ============================================================
  Widget _buildHeadingToCustomer(BuildContext context, DeliveryOrder order) {
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
              target: order.customerLocation,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('customer'),
                position: order.customerLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: order.customerName),
              ),
              Marker(
                markerId: const MarkerId('rider_bike'),
                position: ref.watch(riderLiveLocationProvider) ?? order.storeLocation,
                icon: _twoWheelerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                anchor: const Offset(0.5, 0.5),
                infoWindow: const InfoWindow(title: 'You (Rider)'),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('toCustomer'),
                color: Brand.red,
                width: 5,
                points: [
                  order.storeLocation,
                  order.customerLocation,
                ],
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Bottom Customer Card & Navigation Action
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(fulfillmentProvider.notifier).recordArrivedAtCustomer(
                                  order.orderId,
                                  order.customerLocation.latitude,
                                  order.customerLocation.longitude,
                                );
                          },
                          icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Brand.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

            // 4 OTP Boxes
            OtpCodeBoxes(otp: _enteredOtp, length: 4),

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
                      ? () {
                          ref.read(fulfillmentProvider.notifier).completeCustomerDelivery(
                                orderId: order.orderId,
                                otp: _enteredOtp,
                                isAgeVerified: _isAgeVerified,
                              );
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

            const Spacer(),

            // Custom in-app numeric pad
            CustomNumericKeypad(
              onDigitPressed: (digit) => _onDigitPressed(digit, 4),
              onBackspacePressed: _onBackspacePressed,
            ),
            const SizedBox(height: 12),
          ],
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
