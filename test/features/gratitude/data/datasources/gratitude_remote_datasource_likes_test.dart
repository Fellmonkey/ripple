import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import 'package:ripple/features/gratitude/data/datasources/gratitude_remote_datasource.dart';
import 'package:ripple/core/config/appwrite_config.dart';

class MockTablesDB extends Mock implements TablesDB {}
class MockRow extends Mock implements models.Row {}
class MockRowList extends Mock implements models.RowList {}

void main() {
  late MockTablesDB mockTablesDB;
  late GratitudeRemoteDataSourceImpl dataSource;

  setUp(() async{
    await dotenv.load(fileName: 'assets/.env');

    mockTablesDB = MockTablesDB();
    dataSource = GratitudeRemoteDataSourceImpl(databases: mockTablesDB);
  });

  group('getUserLikedGratitudeIds', () {
    test('returns empty set when gratitudeIds empty', () async {
      final result = await dataSource.getUserLikedGratitudeIds(userId: 'u1', gratitudeIds: []);
      expect(result, isEmpty);
    });

    test('queries user_likes and returns set of ids', () async {
  final mockDocList = MockRowList();
        final mockRow = MockRow();

        when(() => mockTablesDB.listRows(
          databaseId: any(named: 'databaseId'),
          tableId: any(named: 'tableId'),
          queries: any(named: 'queries'),
        )).thenAnswer((_) async => mockDocList);

  when(() => mockDocList.rows).thenReturn([mockRow]);
        when(() => mockRow.data).thenReturn({'gratitudeId': 'g1'});

        final ids = await dataSource.getUserLikedGratitudeIds(userId: 'u1', gratitudeIds: ['g1']);
        expect(ids.contains('g1'), isTrue);
    });
  });

  group('addUserLike & removeUserLike', () {
    test('addUserLike calls createRow', () async {
      when(() => mockTablesDB.createRow(
        databaseId: any(named: 'databaseId'),
        tableId: any(named: 'tableId'),
        rowId: any(named: 'rowId'),
        data: any(named: 'data'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => MockRow());

      await dataSource.addUserLike(userId: 'u1', gratitudeId: 'g1');

      verify(() => mockTablesDB.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userLikesCollectionId,
        rowId: any(named: 'rowId'),
        data: any(named: 'data'),
        permissions: any(named: 'permissions'),
      )).called(1);
    });

    test('removeUserLike deletes found like', () async {
      // Stub listRows to return a DocumentList with one Document-like object
  final mockDocList = MockRowList();
      final mockRow = MockRow();

      when(() => mockTablesDB.listRows(
        databaseId: any(named: 'databaseId'),
        tableId: any(named: 'tableId'),
        queries: any(named: 'queries'),
      )).thenAnswer((_) async => mockDocList);

      when(() => mockDocList.rows).thenReturn([mockRow]);
      when(() => mockRow.$id).thenReturn('like-1');

      when(() => mockTablesDB.deleteRow(
        databaseId: any(named: 'databaseId'),
        tableId: any(named: 'tableId'),
        rowId: any(named: 'rowId'),
      )).thenAnswer((_) async => MockRow());

      await dataSource.removeUserLike(userId: 'u1', gratitudeId: 'g1');

      verify(() => mockTablesDB.deleteRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userLikesCollectionId,
        rowId: 'like-1',
      )).called(1);
    });
  });
}
