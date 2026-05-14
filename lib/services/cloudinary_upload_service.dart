import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ImageUploadValidationException implements Exception {
  final String message;

  const ImageUploadValidationException(this.message);

  @override
  String toString() => message;
}

class CloudinaryUploadService {
  CloudinaryUploadService._();
  static final CloudinaryUploadService instance = CloudinaryUploadService._();

  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _allowedImageExtensions = {'jpg', 'jpeg', 'png'};

  static const _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'djz33mcbv',
  );
  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'boo_uploads',
  );

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<String?> pickAndUploadImage({required String folder}) async {
    if (!isConfigured) {
      throw Exception('Cloudinary is not configured.');
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final file = picked.files.single;
    _validateImageFile(file);

    return uploadFile(file, folder: folder);
  }

  void _validateImageFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension == null || !_allowedImageExtensions.contains(extension)) {
      throw const ImageUploadValidationException(
        'Please upload a JPG or PNG image',
      );
    }

    if (file.size > _maxImageBytes) {
      throw const ImageUploadValidationException(
        'Image must be smaller than 5MB',
      );
    }
  }

  Future<String> uploadFile(
    PlatformFile file, {
    required String folder,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload'),
    );

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = folder;

    final bytes = file.bytes;
    final path = file.path;
    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    } else if (path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', path));
    } else {
      throw Exception('Could not read selected file.');
    }

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    final body = _decodeJsonMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'];
      throw Exception(
        error is Map
            ? error['message']?.toString() ?? 'Upload failed.'
            : 'Upload failed.',
      );
    }

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a file URL.');
    }
    return secureUrl;
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const <String, dynamic>{};
  }
}
