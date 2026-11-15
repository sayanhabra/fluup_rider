import 'dart:async';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/google_map_helper.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_marker_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:adm_rider/modules/earnings/providers/earnings_provider.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/active_delivery_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/new_order_request_modal.dart';
import 'package:adm_rider/modules/notifications/screens/notification_screen.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final LocationHelper _locationHelper = LocationHelper.instance;
  final GoogleMapHelper _mapHelper = GoogleMapHelper.instance;

  bool _isLocationReady = false;
  GoogleMapController? _mapController;
  BitmapDescriptor? _twoWheelerIcon;

  LatLng _currentLocation = const LatLng(22.5726, 88.3639); // Kolkata

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  @override
  void initState() {
    super.initState();
    _initTwoWheelerIcon();
    _checkLocationPermission();
    _initBatteryTracking();
  }

  Future<void> _initTwoWheelerIcon() async {
    try {
      final icon = await TwoWheelerMarkerHelper.instance.getTwoWheelerMarker();
      if (mounted) {
        setState(() {
          _twoWheelerIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Could not load two-wheeler marker icon: $e');
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBatteryTracking() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) async {
        try {
          final newLevel = await _battery.batteryLevel;
          if (mounted) setState(() => _batteryLevel = newLevel);
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _checkLocationPermission() async {
    if (!mounted) return;
    setState(() {
      _isLocationReady = false;
    });

    try {
      final result = await _locationHelper.getLocationWithFallback();
      if (!mounted) return;

      if (result.isSuccess && result.position != null) {
        final position = result.position!;
        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = location;
          _isLocationReady = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapHelper.moveCamera(location, zoom: 15.0);
        });
      } else {
        // Use default Kolkata location for seamless experience
        setState(() {
          _currentLocation = const LatLng(22.5726, 88.3639);
          _isLocationReady = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocation = const LatLng(22.5726, 88.3639);
        _isLocationReady = true;
      });
    }
  }

  Future<void> _recenterMap() async {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 15.0),
        ),
      );
    }
  }

  void _showNewOrderSheet(BuildContext context) {
    final sampleOrder = DeliveryOrder.sample();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewOrderRequestModal(
          order: sampleOrder,
          onAccepted: () async {
            Navigator.of(context).pop();
            await ref
                .read(fulfillmentProvider.notifier)
                .acceptOffer(sampleOrder.orderId);
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
              );
            }
          },
          onRejected: () {
            ref
                .read(fulfillmentProvider.notifier)
                .rejectOffer(sampleOrder.orderId);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationReady) {
      return const DashboardLoadingScreen(
        message: 'Fetching your location... 📍',
      );
    }

    // Auto-listen to 30-sec location updates from RiderLocationTracker:
    // Move the map camera and update the two-wheeler vehicle marker position.
    ref.listen<LatLng?>(riderLiveLocationProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() {
          _currentLocation = next;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(next),
        );
      }
    });

    final liveLocation = ref.watch(riderLiveLocationProvider);
    final currentLocation = liveLocation ?? _currentLocation;

    final currentUser = ref.watch(currentUserProvider);
    final fulfillment = ref.watch(fulfillmentProvider);
    final isOnline = fulfillment.isOnline;
    final activeOrder = fulfillment.activeOrder;
    final earnings = ref.watch(earningsProvider).summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ─── 1. GOOGLE MAP BACKGROUND (Screen 3) ───
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('rider_loc'),
                position: currentLocation,
                icon: _twoWheelerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                anchor: const Offset(0.5, 0.5),
                infoWindow: const InfoWindow(title: 'You are here'),
              ),
            },
            circles: {
              // Radar ripple circle around rider
              Circle(
                circleId: const CircleId('radar_inner'),
                center: currentLocation,
                radius: 250,
                fillColor: Colors.blue.withValues(alpha: 0.18),
                strokeColor: Colors.blue.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
              Circle(
                circleId: const CircleId('radar_outer'),
                center: currentLocation,
                radius: 500,
                fillColor: Colors.blue.withValues(alpha: 0.06),
                strokeColor: Colors.blue.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // ─── 2. TOP HEADER & ONLINE TOGGLE (Screen 3) ───
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Top Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Brand.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, ${currentUser?.name?.isNotEmpty == true ? currentUser!.name : "Rider"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rider ID: ${currentUser != null && currentUser.id > 0 ? "RID${currentUser.id}" : "--"}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                        icon: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // "You are Online" Toggle Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline ? Brand.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOnline
                                      ? 'You are Online'
                                      : 'You are Offline',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOnline
                                      ? 'You will receive delivery requests'
                                      : 'Toggle online to start receiving orders',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isOnline,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Brand.red,
                          onChanged: (val) {
                            ref
                                .read(fulfillmentProvider.notifier)
                                .toggleOnline(
                                  val,
                                  latitude: _currentLocation.latitude,
                                  longitude: _currentLocation.longitude,
                                  batteryLevel: _batteryLevel,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 3. RECENTER MAP BUTTON (Screen 3) ───
          Positioned(
            right: 20,
            bottom: activeOrder != null ? 220 : 160,
            child: FloatingActionButton.small(
              heroTag: 'recenter_rider_loc',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Color(0xFF1E293B)),
            ),
          ),

          // ─── 4. BOTTOM QUICK STATS CARD (Screen 3) ───
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active Ongoing Order Alert Banner
                if (activeOrder != null &&
                    activeOrder.currentStep != DeliveryFlowStep.offerReceived &&
                    activeOrder.currentStep !=
                        DeliveryFlowStep.deliveryCompleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Brand.red,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Brand.red.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Order: ${activeOrder.orderNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Tap to resume navigation',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ActiveDeliveryScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Brand.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Open',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Stats Card: Today's Trips, Earnings, Online Time (from API)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Today's Trips
                      _buildQuickStatItem(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Brand.red,
                        title: "Today's Trips",
                        value: '${earnings.totalTrips}',
                      ),
                      Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),

                      // Earnings
                      _buildQuickStatItem(
                        icon: Icons.lock_outline,
                        iconColor: Brand.warning,
                        title: 'Earnings',
                        value: earnings.formattedTotal,
                      ),
                      Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),

                      // Online Time
                      _buildQuickStatItem(
                        icon: Icons.access_time,
                        iconColor: Colors.blue,
                        title: 'Online Time',
                        value: earnings.onlineTime,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Button to simulate / trigger incoming order (for testing & demoing Screen 4)
                if (activeOrder == null ||
                    activeOrder.currentStep ==
                        DeliveryFlowStep.deliveryCompleted)
                  TextButton.icon(
                    onPressed: () => _showNewOrderSheet(context),
                    icon: const Icon(
                      Icons.flash_on,
                      color: Brand.red,
                      size: 16,
                    ),
                    label: const Text(
                      'Simulate New Delivery Offer',
                      style: TextStyle(
                        color: Brand.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
