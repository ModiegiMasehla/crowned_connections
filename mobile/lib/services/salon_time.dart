/// South African salon wall-clock time (UTC+02:00, no daylight saving).
DateTime salonTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 2));
