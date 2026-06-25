import 'package:intl/intl.dart';

String formatDistanceMeters(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String formatSpeedMps(double metersPerSecond) {
  return '${(metersPerSecond * 3.6).toStringAsFixed(1)} km/h';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return '${seconds}s';
}

String formatShortDate(DateTime dateTime) {
  return DateFormat('EEE, d MMM').format(dateTime);
}

String formatLongDateTime(DateTime dateTime) {
  return DateFormat('d MMM yyyy, h:mm a').format(dateTime);
}

