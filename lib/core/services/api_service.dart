import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ApiService {
  static Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) => Uri.parse('${AppConfig.backendUrl}$path');

  static Future<dynamic> get(String path) =>
      _json(http.get(_uri(path), headers: _headers));

  static Future<Uint8List> getBytes(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    if (res.statusCode >= 400) _fail(res);
    return res.bodyBytes;
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _json(http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  static Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _json(http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  static Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _json(http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  static Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    if (res.statusCode >= 400) _fail(res);
  }

  static Future<dynamic> _json(Future<http.Response> req) async {
    final res = await req;
    if (res.statusCode >= 400) _fail(res);
    return jsonDecode(res.body);
  }

  static Never _fail(http.Response res) {
    String msg = 'İstek başarısız (${res.statusCode})';
    try {
      msg = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }
}
