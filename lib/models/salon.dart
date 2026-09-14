import 'package:cloud_firestore/cloud_firestore.dart';

/// A single service a salon offers, e.g. "Braiding - R350 - 120 mins".
class ServiceItem {
  final String name;
  final double price;
  final int durationMinutes;

  ServiceItem({
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'durationMinutes': durationMinutes};
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      durationMinutes: (map['durationMinutes'] ?? 30).toInt(),
    );
  }
}

/// Opening/closing time for a single day of the week.
/// Stored as simple "HH:mm" strings to keep this a foundational,
/// easy-to-read example rather than pulling in a time-range package.
class WorkingHours {
  final String open; // e.g. "09:00"
  final String close; // e.g. "18:00"
  final bool closed; // true if the salon does not open that day

  WorkingHours({required this.open, required this.close, this.closed = false});

  Map<String, dynamic> toMap() {
    return {'open': open, 'close': close, 'closed': closed};
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      open: map['open'] ?? '09:00',
      close: map['close'] ?? '17:00',
      closed: map['closed'] ?? false,
    );
  }

  String get display => closed ? 'Closed' : '$open - $close';
}

/// Represents a document in the `salons` Firestore collection.
class Salon {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> serviceTypes; // tags used for search, e.g. ["Nails"]
  final List<ServiceItem> services; // detailed price list
  final Map<String, WorkingHours> workingHours; // key = weekday name

  Salon({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.serviceTypes,
    required this.services,
    required this.workingHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'serviceTypes': serviceTypes,
      'services': services.map((s) => s.toMap()).toList(),
      'workingHours': workingHours.map((day, hrs) => MapEntry(day, hrs.toMap())),
    };
  }

  factory Salon.fromMap(String id, Map<String, dynamic> map) {
    final hoursMap = <String, WorkingHours>{};
    final rawHours = (map['workingHours'] ?? {}) as Map<String, dynamic>;
    rawHours.forEach((day, value) {
      hoursMap[day] = WorkingHours.fromMap(Map<String, dynamic>.from(value));
    });

    return Salon(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      serviceTypes: List<String>.from(map['serviceTypes'] ?? []),
      services: (map['services'] as List<dynamic>? ?? [])
          .map((s) => ServiceItem.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      workingHours: hoursMap,
    );
  }
}

/// Helper class used only in memory (never written to Firestore) to keep a
/// Salon alongside its computed distance from the client's current location.
class SalonWithDistance {
  final Salon salon;
  final double distanceKm;

  SalonWithDistance({required this.salon, required this.distanceKm});
}
