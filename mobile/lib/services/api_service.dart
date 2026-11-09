import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // *** NGROK VEYA SUNUCU LINKI ***
  static const String serverUrl = "http://10.0.2.2:8000/";

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      var request = http.MultipartRequest('POST', Uri.parse("${serverUrl}upload/"));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception("Sunucu Hatası: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Bağlantı Hatası: $e");
    }
  }

  static Future<Map<String, dynamic>> sendBarcode(String barcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      var response = await http.post(
        Uri.parse("${serverUrl}barcode/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"barcode": barcode, "user_id": userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception("Ürün bulunamadı.");
      } else {
        throw Exception("Sunucu Hatası: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Hata: $e");
    }
  }
}

