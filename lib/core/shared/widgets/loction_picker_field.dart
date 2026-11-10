// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:http/http.dart' as http;

// const String kGoogleApiKey = "AIzaSyCkgyvNZ3rRNEh45y24PzAg6GfqbC7KwG0";

// class LocationData {
//   final double lat;
//   final double lng;
//   final String address;

//   const LocationData({
//     required this.lat,
//     required this.lng,
//     required this.address,
//   });

//   @override
//   String toString() => address;
// }

// class PlacePrediction {
//   final String placeId;
//   final String description;

//   PlacePrediction({required this.placeId, required this.description});

//   factory PlacePrediction.fromJson(Map<String, dynamic> json) {
//     return PlacePrediction(
//       placeId: json['place_id'] ?? '',
//       description: json['description'] ?? '',
//     );
//   }
// }

// /// ---------------------------------------------------------------------
// /// Form Field Wrapper
// /// ---------------------------------------------------------------------
// class LocationPickerField extends FormField<LocationData> {
//   LocationPickerField({
//     super.key,
//     LocationData? initialValue,
//     FormFieldSetter<LocationData>? onSaved,
//     FormFieldValidator<LocationData>? validator,
//     super.autovalidateMode,
//     String label = "Delivery Location",
//   }) : super(
//          initialValue: initialValue,
//          onSaved: onSaved,
//          validator: validator,
//          builder: (FormFieldState<LocationData> state) {
//            return _LocationPickerFieldContent(state: state, label: label);
//          },
//        );
// }

// class _LocationPickerFieldContent extends StatefulWidget {
//   final FormFieldState<LocationData> state;
//   final String label;

//   const _LocationPickerFieldContent({required this.state, required this.label});

//   @override
//   State<_LocationPickerFieldContent> createState() =>
//       _LocationPickerFieldContentState();
// }

// class _LocationPickerFieldContentState
//     extends State<_LocationPickerFieldContent> {
//   bool _loadingInitial = false;

//   LocationData? get _value => widget.state.value;

//   @override
//   void initState() {
//     super.initState();
//     if (_value == null) {
//       _loadCurrentLocationAsDefault();
//     }
//   }

//   Future<void> _loadCurrentLocationAsDefault() async {
//     setState(() => _loadingInitial = true);
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) return;

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         return;
//       }

//       Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       String address = "Current location";
//       try {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           pos.latitude,
//           pos.longitude,
//         );
//         if (placemarks.isNotEmpty) {
//           final p = placemarks.first;
//           address = [
//             p.name,
//             p.subLocality,
//             p.locality,
//             p.administrativeArea,
//           ].where((e) => e != null && e.isNotEmpty).join(', ');
//         }
//       } catch (_) {}

//       widget.state.didChange(
//         LocationData(lat: pos.latitude, lng: pos.longitude, address: address),
//       );
//     } catch (_) {
//     } finally {
//       if (mounted) setState(() => _loadingInitial = false);
//     }
//   }

//   Future<void> _openPicker() async {
//     final result = await Navigator.push<LocationData>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => LocationPickerScreen(initialValue: _value),
//       ),
//     );
//     if (result != null) {
//       widget.state.didChange(result);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasValue = _value != null;
//     final borderColor = widget.state.hasError
//         ? Theme.of(context).colorScheme.error
//         : Colors.grey.shade300;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
//         const SizedBox(height: 6),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: borderColor),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           clipBehavior: Clip.antiAlias,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               SizedBox(
//                 height: 130,
//                 child: _loadingInitial
//                     ? const Center(child: CircularProgressIndicator())
//                     : hasValue
//                     ? Stack(
//                         children: [
//                           GoogleMap(
//                             initialCameraPosition: CameraPosition(
//                               target: LatLng(_value!.lat, _value!.lng),
//                               zoom: 15,
//                             ),
//                             markers: {
//                               Marker(
//                                 markerId: const MarkerId('preview'),
//                                 position: LatLng(_value!.lat, _value!.lng),
//                               ),
//                             },
//                             zoomControlsEnabled: false,
//                             scrollGesturesEnabled: false,
//                             rotateGesturesEnabled: false,
//                             tiltGesturesEnabled: false,
//                             zoomGesturesEnabled: false,
//                             liteModeEnabled: true,
//                           ),
//                           Positioned.fill(
//                             child: Material(
//                               color: Colors.transparent,
//                               child: InkWell(onTap: _openPicker),
//                             ),
//                           ),
//                         ],
//                       )
//                     : InkWell(
//                         onTap: _openPicker,
//                         child: Container(
//                           color: Colors.grey.shade100,
//                           child: const Center(
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.map_outlined,
//                                   size: 32,
//                                   color: Colors.grey,
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   "Tap to set location",
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.location_on,
//                       size: 20,
//                       color: Colors.indigo,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         hasValue ? _value!.address : "No location selected",
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: hasValue ? Colors.black87 : Colors.grey,
//                         ),
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: _openPicker,
//                       child: Text(hasValue ? "Change" : "Set location"),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (widget.state.hasError)
//           Padding(
//             padding: const EdgeInsets.only(top: 6, left: 4),
//             child: Text(
//               widget.state.errorText ?? '',
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.error,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// /// ---------------------------------------------------------------------
// /// Location Picker Screen with Reliable REST Places Search
// /// ---------------------------------------------------------------------
// class LocationPickerScreen extends StatefulWidget {
//   final LocationData? initialValue;

//   const LocationPickerScreen({super.key, this.initialValue});

//   @override
//   State<LocationPickerScreen> createState() => _LocationPickerScreenState();
// }

// class _LocationPickerScreenState extends State<LocationPickerScreen> {
//   final Completer<GoogleMapController> _controller = Completer();
//   final TextEditingController _searchController = TextEditingController();

//   late LatLng _pickedLocation;
//   String _address = "";
//   List<PlacePrediction> _predictions = [];
//   bool _loadingAddress = false;

//   Timer? _debounceTimer;
//   Timer? _searchDebounceTimer;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.initialValue != null) {
//       _pickedLocation = LatLng(
//         widget.initialValue!.lat,
//         widget.initialValue!.lng,
//       );
//       _address = widget.initialValue!.address;
//     } else {
//       _pickedLocation = const LatLng(22.5726, 88.3639);
//       _getCurrentLocation();
//     }
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _searchDebounceTimer?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }
//     if (permission == LocationPermission.deniedForever) return;

//     try {
//       Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       final newPos = LatLng(pos.latitude, pos.longitude);

//       if (_controller.isCompleted) {
//         final controller = await _controller.future;
//         controller.animateCamera(CameraUpdate.newLatLng(newPos));
//       }
//       _fetchAddressForLocation(newPos);
//     } catch (_) {}
//   }

//   void _onCameraIdle() {
//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(const Duration(milliseconds: 400), () {
//       _fetchAddressForLocation(_pickedLocation);
//     });
//   }

//   Future<void> _fetchAddressForLocation(LatLng latLng) async {
//     if (!mounted) return;
//     setState(() => _loadingAddress = true);

//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         latLng.latitude,
//         latLng.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         final parts = [
//           p.name,
//           p.subLocality,
//           p.locality,
//           p.administrativeArea,
//           p.postalCode,
//         ].where((e) => e != null && e.isNotEmpty).join(', ');

//         if (mounted) {
//           setState(() {
//             _address = parts;
//             _pickedLocation = latLng;
//           });
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _address = "Unable to fetch address");
//     } finally {
//       if (mounted) setState(() => _loadingAddress = false);
//     }
//   }

//   void _onSearchChanged(String query) {
//     _searchDebounceTimer?.cancel();
//     if (query.trim().isEmpty) {
//       setState(() => _predictions = []);
//       return;
//     }
//     _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$kGoogleApiKey',
//       );

//       try {
//         final response = await http.get(url);
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           if (data['status'] == 'OK') {
//             final list = (data['predictions'] as List)
//                 .map((p) => PlacePrediction.fromJson(p))
//                 .toList();
//             if (mounted) setState(() => _predictions = list);
//           } else {
//             debugPrint(
//               "Places API Error: ${data['status']} - ${data['error_message']}",
//             );
//             if (mounted) setState(() => _predictions = []);
//           }
//         }
//       } catch (e) {
//         debugPrint("Search request failed: $e");
//       }
//     });
//   }

//   Future<void> _selectPrediction(PlacePrediction prediction) async {
//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$kGoogleApiKey',
//     );

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'OK' && data['result']['geometry'] != null) {
//           final loc = data['result']['geometry']['location'];
//           final target = LatLng(loc['lat'], loc['lng']);

//           setState(() {
//             _predictions = [];
//             _searchController.text = prediction.description;
//           });

//           FocusScope.of(context).unfocus();

//           if (_controller.isCompleted) {
//             final controller = await _controller.future;
//             controller.animateCamera(CameraUpdate.newLatLng(target));
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Place details request failed: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Pick Location")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: _pickedLocation,
//               zoom: 15,
//             ),
//             onMapCreated: (c) {
//               if (!_controller.isCompleted) {
//                 _controller.complete(c);
//               }
//             },
//             onCameraMove: (pos) => _pickedLocation = pos.target,
//             onCameraIdle: _onCameraIdle,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//           ),
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.only(bottom: 35),
//               child: Icon(Icons.location_pin, size: 45, color: Colors.red),
//             ),
//           ),
//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Column(
//               children: [
//                 Material(
//                   elevation: 4,
//                   borderRadius: BorderRadius.circular(8),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: _onSearchChanged,
//                     decoration: InputDecoration(
//                       hintText: "Search location...",
//                       prefixIcon: const Icon(Icons.search),
//                       suffixIcon: _searchController.text.isNotEmpty
//                           ? IconButton(
//                               icon: const Icon(Icons.clear),
//                               onPressed: () {
//                                 _searchController.clear();
//                                 setState(() => _predictions = []);
//                               },
//                             )
//                           : null,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 14,
//                       ),
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 if (_predictions.isNotEmpty)
//                   Material(
//                     elevation: 4,
//                     borderRadius: BorderRadius.circular(8),
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxHeight: 220),
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: _predictions.length,
//                         itemBuilder: (context, i) {
//                           final p = _predictions[i];
//                           return ListTile(
//                             leading: const Icon(Icons.place_outlined),
//                             title: Text(p.description),
//                             onTap: () => _selectPrediction(p),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 140,
//             right: 16,
//             child: FloatingActionButton(
//               heroTag: "currentLocationBtn",
//               onPressed: _getCurrentLocation,
//               child: const Icon(Icons.my_location),
//             ),
//           ),
//           Positioned(
//             bottom: 20,
//             left: 16,
//             right: 16,
//             child: Card(
//               elevation: 6,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _loadingAddress
//                         ? const Row(
//                             children: [
//                               SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                               SizedBox(width: 8),
//                               Text("Fetching address..."),
//                             ],
//                           )
//                         : Text(
//                             _address.isEmpty
//                                 ? "Move the map to pick a location"
//                                 : _address,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(fontWeight: FontWeight.w500),
//                           ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _loadingAddress
//                             ? null
//                             : () {
//                                 Navigator.pop(
//                                   context,
//                                   LocationData(
//                                     lat: _pickedLocation.latitude,
//                                     lng: _pickedLocation.longitude,
//                                     address: _address,
//                                   ),
//                                 );
//                               },
//                         child: const Text("Confirm Location"),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
