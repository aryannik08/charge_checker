import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String apiKey = '7c9d13174031404ba2b94231252609';
  String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  final http.Client httpClient;

  ApiService({http.Client? httpClient}) : httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> getJson(String pathOrUrl) async {
    final Uri url = _buildUrl(pathOrUrl);
    final http.Response response = await httpClient.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('GET $url failed: ${response.statusCode}');
  }

  Future<List<dynamic>> getJsonList(String pathOrUrl) async {
    final Uri url = _buildUrl(pathOrUrl);
    final http.Response response = await httpClient.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('GET $url failed: ${response.statusCode}');
  }

  Uri _buildUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Uri.parse(pathOrUrl);
    }
    return Uri.parse('$baseUrl$pathOrUrl');
  }
}


