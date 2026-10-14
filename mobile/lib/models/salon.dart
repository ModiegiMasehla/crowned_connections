class Salon {
  final String id;
  final String name;
  final String? description;
  final String city;
  final String province;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int ratingCount;
  final double? distanceKm;

  Salon({
    required this.id,
    required this.name,
    this.description,
    required this.city,
    required this.province,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.ratingCount = 0,
    this.distanceKm,
  });

  factory Salon.fromJson(Map<String,dynamic> j) => Salon(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    city: j['city'] ?? '',
    province: j['province'] ?? '',
    latitude: j['latitude'] == null ? null : double.parse(j['latitude'].toString()),
    longitude: j['longitude'] == null ? null : double.parse(j['longitude'].toString()),
    rating: double.tryParse((j['rating_avg'] ?? 0).toString()) ?? 0,
    ratingCount: int.tryParse((j['rating_count'] ?? 0).toString()) ?? 0,
    distanceKm: j['distance_km'] == null ? null : double.parse(j['distance_km'].toString()),
  );
}
