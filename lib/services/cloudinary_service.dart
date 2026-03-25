import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cloudinary'ye resim yükler ve URL döner.
/// Hem post fotoğrafları hem de profil fotoğrafı bu servisi kullanır.
class CloudinaryService {
  static const String _cloudName = "da7gq8fdo";
  static const String _uploadPreset = "pilates_unsigned";

  static Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri);
    request.fields["upload_preset"] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) return null;

    final json = jsonDecode(body);
    return json["secure_url"] as String?;
  }
}
