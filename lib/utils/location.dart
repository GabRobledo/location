import 'dart:math';

double calculateDistance(
  double? lat1,
  double? lon1,
  double? lat2,
  double? lon2,
) {
  const int radius = 6371; // Radius of the Earth in kilometers

  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
    return 0.0; // Handle null values by returning a default value
  }

  // Convert latitude and longitude to radians
  double lat1Rad = lat1 * (pi / 180);
  double lon1Rad = lon1 * (pi / 180);
  double lat2Rad = lat2 * (pi / 180);
  double lon2Rad = lon2 * (pi / 180);

  // Calculate the differences between the coordinates
  double dLat = lat2Rad - lat1Rad;
  double dLon = lon2Rad - lon1Rad;

  // Apply the Haversine formula
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * asin(sqrt(a));

  // Calculate the distance in meters
  double distance = radius * c * 1000;
  return distance;
}
