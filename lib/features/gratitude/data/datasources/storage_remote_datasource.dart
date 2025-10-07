import 'dart:io';
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';

/// Remote datasource for storage operations (photos)
abstract class StorageRemoteDataSource {
  /// Upload photo to Appwrite Storage
  Future<String> uploadPhoto(String filePath);
  
  /// Delete photo from Appwrite Storage
  Future<void> deletePhoto(String fileId);
  
  /// Get photo URL
  String getPhotoUrl(String fileId);
}

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final Storage storage;

  StorageRemoteDataSourceImpl({
    required this.storage,
  });

  @override
  Future<String> uploadPhoto(String filePath) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;

    final uploadedFile = await storage.createFile(
      bucketId: AppwriteConfig.photosBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath, filename: fileName),
    );

    // Return file URL
    return getPhotoUrl(uploadedFile.$id);
  }

  @override
  Future<void> deletePhoto(String fileId) async {
    await storage.deleteFile(
      bucketId: AppwriteConfig.photosBucketId,
      fileId: fileId,
    );
  }

  @override
  String getPhotoUrl(String fileId) {
    // Return full URL to photo
    return '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.photosBucketId}/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }
}
