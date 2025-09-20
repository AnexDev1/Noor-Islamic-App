import 'dart:convert';
import 'package:http/http.dart' as http;

class QiblaApi {
  static Future<double> getQiblaDirection(double latitude, double longitude) async {
    final url = 'https://api.aladhan.com/v1/qibla/$latitude/$longitude';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data']['direction'] as num).toDouble();
    } else {
      throw Exception('Failed to fetch Qibla direction');
    }
  }
}

