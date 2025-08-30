import 'package:dio/dio.dart';
import '../models/favorite.dart';

class FavoritesRepo {
  final Dio _dio;
  FavoritesRepo(this._dio);

  Future<List<FavoriteList>> getLists() async {
    final res = await _dio.get('/favorites/lists');
    return (res.data as List).map((e) => FavoriteList.fromJson(e)).toList();
  }

  Future<FavoriteList> createList(String name) async {
    final res = await _dio.post('/favorites/lists', data: { 'name': name });
    return FavoriteList.fromJson(res.data);
  }

  Future<FavoriteList> renameList(int listId, String name) async {
    final res = await _dio.patch('/favorites/lists/$listId', data: { 'name': name });
    return FavoriteList.fromJson(res.data);
  }

  Future<void> deleteList(int listId) async {
    await _dio.delete('/favorites/lists/$listId');
  }

  Future<List<FavoriteItem>> getItems({int? listId, int page = 1, int limit = 20}) async {
    final res = await _dio.get('/favorites/items', queryParameters: {
      if (listId != null) 'list_id': listId,
      'page': page,
      'limit': limit,
    });
    return (res.data as List).map((e) => FavoriteItem.fromJson(e)).toList();
  }

  /// Toggle in default list by default
  Future<FavoriteItem> toggle({required int cropId, int? listId}) async {
    final res = await _dio.post('/favorites/toggle', data: {
      'crop_id': cropId,
      if (listId != null) 'list_id': listId,
    });
    return FavoriteItem.fromJson(res.data);
  }

  Future<FavoriteItem> add({required int cropId, int? listId}) async {
    final res = await _dio.post('/favorites/items', data: {
      'crop_id': cropId,
      if (listId != null) 'list_id': listId,
    });
    return FavoriteItem.fromJson(res.data);
  }

  Future<void> remove(int itemId) async {
    await _dio.delete('/favorites/items/$itemId');
  }

  Future<List<Map<String, dynamic>>> summary() async {
    final res = await _dio.get('/favorites/summary');
    // [{list_id, name, is_default, count}, ...]
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
