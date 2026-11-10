class SelectedLocation {
  final double latitude;
  final double longitude;
  final String address;

  final Map<String, dynamic>? addressData;

  const SelectedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressData,
  });

  @override
  String toString() {
    return 'SelectedLocation('
        'latitude: $latitude, '
        'longitude: $longitude, '
        'address: $address'
        ')';
  }
}
