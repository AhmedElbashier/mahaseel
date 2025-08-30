class FavoriteList {
  final int id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;

  FavoriteList({required this.id, required this.name, required this.isDefault, required this.createdAt});

  factory FavoriteList.fromJson(Map<String, dynamic> j) => FavoriteList(
    id: j['id'],
    name: j['name'],
    isDefault: j['is_default'] ?? j['isDefault'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
  );
}

class FavoriteItem {
  final int id;       // 0 means “just toggled OFF” (per our API)
  final int cropId;
  final int listId;
  final DateTime createdAt;

  FavoriteItem({required this.id, required this.cropId, required this.listId, required this.createdAt});

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
    id: j['id'],
    cropId: j['crop_id'] ?? j['cropId'],
    listId: j['list_id'] ?? j['listId'],
    createdAt: DateTime.parse(j['created_at']),
  );
}
