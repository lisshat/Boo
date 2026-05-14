import 'dart:convert';

import 'package:boo/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadedVerificationFile {
  final String documentType;
  final String fileName;
  final String fileUrl;

  const UploadedVerificationFile({
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
  });
}

class VerificationUploadService {
  VerificationUploadService._();
  static final VerificationUploadService instance =
      VerificationUploadService._();

  static const _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'djz33mcbv',
  );
  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'boo_uploads',
  );

  bool get isCloudinaryConfigured =>
      _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<UploadedVerificationFile?> pickAndUpload({
    required String documentType,
  }) async {
    if (!isCloudinaryConfigured) {
      throw Exception(
        'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'pdf',
        'doc',
        'docx',
      ],
    );
    if (picked == null || picked.files.isEmpty) return null;

    final file = picked.files.single;
    final url = await _uploadToCloudinary(file);
    return UploadedVerificationFile(
      documentType: documentType,
      fileName: file.name,
      fileUrl: url,
    );
  }

  Future<String> _uploadToCloudinary(PlatformFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload'),
    );

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'boo/verification';

    final bytes = file.bytes;
    final path = file.path;
    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    } else if (path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', path));
    } else {
      throw Exception('Could not read selected file');
    }

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['error'] is Map
            ? body['error']['message']?.toString() ?? 'Upload failed'
            : 'Upload failed',
      );
    }

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a file URL');
    }
    return secureUrl;
  }

  Future<void> submitDocument(UploadedVerificationFile file) async {
    final response = await ApiService.instance.post('/verification/upload', {
      'documentType': file.documentType,
      'fileUrl': file.fileUrl,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'];
      throw Exception(
        message is List
            ? message.first.toString()
            : message?.toString() ?? 'Could not submit verification document',
      );
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await ApiService.instance.get('/verification/status');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Could not load verification status');
  }
}
