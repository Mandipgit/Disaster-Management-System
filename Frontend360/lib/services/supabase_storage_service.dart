import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'reports';

  /// Compresses the image before uploading
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );
      
      return result != null ? File(result.path) : file;
    } catch (e) {
      return file;
    }
  }

  /// Uploads a single file to Supabase Storage and returns its public URL
  Future<String> uploadImage(File file) async {
    try {
      final File compressedFile = await _compressImage(file);
      
      final String fileExtension = compressedFile.path.split('.').last;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$fileExtension';

      // Upload file to Supabase Storage
      await _client.storage.from(_bucketName).upload(
        fileName,
        compressedFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Get public URL
      final String publicUrl = _client.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads multiple files and returns their public URLs
  Future<List<String>> uploadImages(List<File> files) async {
    try {
      final List<String> urls = await Future.wait(
        files.map((file) => uploadImage(file)),
      );
      return urls;
    } catch (e) {
      // In a robust implementation, if an upload fails mid-way, you might want to 
      // delete the already uploaded images. However, keeping them orphaned is 
      // safer than partial local state in most MVP scenarios.
      throw Exception('Failed to upload one or more images: $e');
    }
  }
}
