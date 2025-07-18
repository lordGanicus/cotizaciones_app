import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 Esto es importante

class CloudinaryService {
  final String cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME');
  final String uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET');
  final String apiKey = dotenv.get('CLOUDINARY_API_KEY');
  final String apiSecret = dotenv.get('CLOUDINARY_API_SECRET');

  /// Sube imagen a Cloudinary y devuelve Map con 'secure_url' y 'public_id'
  Future<Map<String, String>?> subirImagen(String imagePath) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final imageFile = File(imagePath);

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);
      return {
        'secure_url': data['secure_url'],
        'public_id': data['public_id'],
      };
    } else {
      print('Error al subir imagen: ${response.statusCode}');
      return null;
    }
  }

  /// Elimina imagen en Cloudinary usando public_id con autenticación firmada
  Future<bool> eliminarImagen(String publicId) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    final String toSign = 'public_id=$publicId&timestamp=$timestamp';
    final signature = sha1.convert(utf8.encode(toSign + apiSecret)).toString();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': apiKey,
        'signature': signature,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 'ok') {
        return true;
      } else {
        print('Cloudinary respuesta: ${data['result']}');
        return false;
      }
    } else {
      print('Error al eliminar imagen: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}
