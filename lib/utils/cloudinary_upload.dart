import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String cloudName = 'ds9subkxg'; // Tu cloud name de Cloudinary
const String uploadPreset = 'flutter_unsigned_upload'; // Tu upload preset

Future<String?> subirImagenCloudinary(String filePath) async {
  try {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = json.decode(respStr);
      return jsonResponse['secure_url'] as String?;
    } else {
      print('Error al subir imagen a Cloudinary: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Excepción al subir imagen a Cloudinary: $e');
    return null;
  }
}