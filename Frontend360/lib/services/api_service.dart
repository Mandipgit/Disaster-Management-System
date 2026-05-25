import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:disaster360/services/session_service.dart';

class ApiService {
  // Configured to the PC's actual local IPv4 address so physical Android devices on Wi-Fi can connect
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.80:8000';
  }

  Future<Map<String, String>> _getHeaders({Map<String, String>? customHeaders}) async {
    final token = SessionService().token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(uri, headers: await _getHeaders(customHeaders: headers));
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool isForm = false}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    if (isForm) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    
    final response = await http.post(
      uri,
      headers: headers,
      body: isForm ? body : (body != null ? jsonEncode(body) : null),
    );
    return _handleResponse(response);
  }

  Future<dynamic> multipartPost(String endpoint, String filePath) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    final headers = await _getHeaders();
    // MultipartRequest doesn't need Content-Type JSON, it manages bounded form-data automatically
    headers.remove('Content-Type'); 
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded != null && decoded is Map && decoded.containsKey('detail')) {
          errorMessage = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
