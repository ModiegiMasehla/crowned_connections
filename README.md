 Crowned Connections 👑

A Flutter + Firebase mobile app that works like a mini Booking.com for
salons: clients search for salons near them by service type, view working
hours and prices, request a booking, and chat with the salon owner to
confirm it. Salon owners manage their salon profile and respond to booking
requests.

Built for a Mobile Development elective to demonstrate:
- **Dart**: classes, models, async/await, enums, null safety
- **Flutter**: navigation, forms, StreamBuilder/FutureBuilder, state
  management with setState, Material 3 widgets
- **Firebase Authentication**: email/password sign-up and sign-in, with a
  role (client vs salon owner) stored per user
- **Cloud Firestore**: real-time data for salons, bookings, and chat
- **Device features**: GPS location (geolocator) and address geocoding

---

## App structure

```
lib/
  models/            Plain Dart classes: AppUser, Salon, ServiceItem,
                      WorkingHours, Booking, ChatMessage
  services/           All Firebase/device logic lives here, not in widgets:
                      auth_service.dart, firestore_service.dart,
                      chat_service.dart, location_service.dart
  screens/
    auth/             Login and Sign up (with role selector)
    client/           Search salons, salon detail, booking, my bookings
    owner/             Manage salon profile, view/respond to bookings
    chat/              Shared chat screen used by both roles
    role_router.dart  Decides Login vs Client Home vs Owner Home
  widgets/            Reusable UI pieces (SalonCard)
  utils/constants.dart Colours, collection names, service type list
```

### How the data fits together (Firestore)

```
users/{uid}                -> name, email, role ("client" | "owner"), phone
salons/{salonId}           -> ownerId, name, address, lat, lng,
                               serviceTypes[], services[], workingHours{}
bookings/{bookingId}       -> clientId, ownerId, salonId, serviceName,
                               price, dateTime, status
chats/{bookingId}/messages -> senderId, senderName, text, timestamp
```

Each booking automatically gets its own private chat thread (the chat
document id IS the booking id) - that's what lets the client and salon
owner "communicate and confirm a booking" as required.

