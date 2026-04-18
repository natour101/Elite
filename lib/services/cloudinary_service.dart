import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';

class CloudinaryService {
  const CloudinaryService();

  Future<String> uploadProductImage(XFile file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signaturePayload =
        'folder=${AppConstants.cloudinaryFolder}&timestamp=$timestamp${AppConstants.cloudinaryApiSecret}';
    final signature =
        sha1.convert(utf8.encode(signaturePayload)).toString();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
      ),
    )
      ..fields['api_key'] = AppConstants.cloudinaryApiKey
      ..fields['folder'] = AppConstants.cloudinaryFolder
      ..fields['timestamp'] = '$timestamp'
      ..fields['signature'] = signature;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('فشل رفع الصورة إلى Cloudinary.');
    }

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = payload['secure_url'] as String? ?? '';
    if (secureUrl.isEmpty) {
      throw Exception('لم يتم استلام رابط الصورة من Cloudinary.');
    }

    return secureUrl;
  }
}
