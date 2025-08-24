import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crops_repo.dart';

class CropFilters {
  final String? type;
  final String? state;
  final double? minPrice;
  final double? maxPrice;
  final SortOption sort;

  const CropFilters({
    this.type,
    this.state,
    this.minPrice,
    this.maxPrice,
    this.sort = SortOption.newest,
  });

  CropFilters copyWith({
    String? type,
    String? state,
    double? minPrice,
    double? maxPrice,
    SortOption? sort,
  }) {
    return CropFilters(
      type: type ?? this.type,
      state: state ?? this.state,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'state': state,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'sort': sort.name,
  };

  factory CropFilters.fromMap(Map<String, dynamic> map) {
    final sortName = (map['sort'] as String?) ?? SortOption.newest.name;
    final sort = SortOption.values.firstWhere(
          (s) => s.name == sortName,
      orElse: () => SortOption.newest,
    );
    return CropFilters(
      type: map['type'] as String?,
      state: map['state'] as String?,
      minPrice: (map['minPrice'] as num?)?.toDouble(),
      maxPrice: (map['maxPrice'] as num?)?.toDouble(),
      sort: sort,
    );
  }

  static const _key = 'mahaseel_last_filters';

  static Future<void> save(CropFilters f) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(f.toMap()));
  }

  static Future<CropFilters> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return const CropFilters(); // defaults
    try {
      return CropFilters.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CropFilters();
    }
  }
}
