import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Represents a document in the `bookings` Firestore collection.
/// This is the record that links a client, a salon and a chosen service
/// together, and is also used as the chat "room" id (see ChatService).
class Booking {
  final String id;
  final String clientId;
  final String clientName;
  final String salonId;
  final String salonName;
  final String ownerId;
  final String serviceName;
  final double price;
  final DateTime dateTime;
  final BookingStatus status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.salonId,
    required this.salonName,
    required this.ownerId,
    required this.serviceName,
    required this.price,
    required this.dateTime,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'salonId': salonId,
      'salonName': salonName,
      'ownerId': ownerId,
      'serviceName': serviceName,
      'price': price,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      salonId: map['salonId'] ?? '',
      salonName: map['salonName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: bookingStatusFromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      clientId: clientId,
      clientName: clientName,
      salonId: salonId,
      salonName: salonName,
      ownerId: ownerId,
      serviceName: serviceName,
      price: price,
      dateTime: dateTime,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
