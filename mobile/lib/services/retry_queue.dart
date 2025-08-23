import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class RetryQueue {
  final Box _box = Hive.box('pending_ops');
  static const _kKey = 'ops';

  List<Map<String, dynamic>> get _ops {
    final raw = (_box.get(_kKey, defaultValue: <String>[]) as List).cast<String>();
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  void enqueueCreateCrop(Map<String, dynamic> payload) {
    final list = _ops;
    final op = {
      'type': 'create_crop',
      'payload': payload,
      'ts': DateTime.now().toIso8601String(),
    };
    list.add(op);
    _box.put(_kKey, list.map(jsonEncode).toList());

    //  Crashlytics breadcrumbs (no PII)
    final count = list.length;
    FirebaseCrashlytics.instance.log('retry_queue: enqueued type=create_crop count=$count');
    FirebaseCrashlytics.instance.setCustomKey('queued_ops_count', count);
  }

  Future<void> flush(Dio dio) async {
    final list = _ops;

    if (list.isEmpty) {
      // optional breadcrumb when nothing to do
      FirebaseCrashlytics.instance.log('retry_queue: flush skipped (empty)');
      return;
    }

    int successes = 0, failures = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final op in list) {
      try {
        if (op['type'] == 'create_crop') {
          await dio.post('/crops', data: op['payload']);
          successes++;
        } else {
          // Unknown op types are kept for future versions
          remaining.add(op);
        }
      } catch (e, st) {
        failures++;
        remaining.add(op);
        // record non-fatal error (don’t send PII)
        FirebaseCrashlytics.instance.recordError(
          e, st,
          reason: 'retry_queue: flush op failed',
          fatal: false,
        );
      }
    }

    _box.put(_kKey, remaining.map(jsonEncode).toList());

    // summarize the flush
    FirebaseCrashlytics.instance.log(
      'retry_queue: flush done success=$successes failure=$failures remaining=${remaining.length}',
    );
    FirebaseCrashlytics.instance.setCustomKey('queued_ops_count', remaining.length);
  }

  int pendingCount() => _ops.length;
}
