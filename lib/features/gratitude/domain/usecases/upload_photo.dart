import '../../../../core/error/models/result.dart';
import '../../../../core/error/exception_handler.dart';
import '../../data/datasources/storage_remote_datasource.dart';

/// Upload photo to Appwrite Storage
abstract class UploadPhotoUseCase {
  /// Upload photo and return URL
  /// Returns Result with photo URL or Failure
  Future<Result<String>> call(String filePath);
}

class UploadPhotoUseCaseImpl implements UploadPhotoUseCase {
  final StorageRemoteDataSource storageDatasource;
  
  UploadPhotoUseCaseImpl({required this.storageDatasource});
  
  @override
  Future<Result<String>> call(String filePath) async {
    try {
      final photoUrl = await storageDatasource.uploadPhoto(filePath);
      return Success(photoUrl);
    } catch (e) {
      final failure = AppwriteExceptionHandler.handleGeneralException(e);
      return Error(failure);
    }
  }
}
