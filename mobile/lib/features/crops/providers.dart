// lib/features/crops/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/crops_repo.dart';


final cropsRepoProvider = Provider<CropsRepo>((ref) => CropsRepo());
