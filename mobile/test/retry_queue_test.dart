import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mahaseel/services/retry_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/firebase_crashlytics');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (method) async {});

  late Directory dir;
  late RetryQueue queue;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('pending_ops');
    queue = RetryQueue();
    Hive.box('pending_ops').clear();
  });

  tearDown(() async {
    await Hive.box('pending_ops').clear();
    await Hive.box('pending_ops').close();
    await dir.delete(recursive: true);
  });

  test('enqueue and flush success', () async {
    queue.enqueueCreateCrop({'name': 'apple'});
    expect(queue.pendingCount(), 1);

    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      h.resolve(Response(requestOptions: o, statusCode: 200, data: {}));
    }));

    await queue.flush(dio);
    expect(queue.pendingCount(), 0);
  });

  test('flush failure keeps op', () async {
    queue.enqueueCreateCrop({'name': 'apple'});
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      h.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError));
    }));

    await queue.flush(dio);
    expect(queue.pendingCount(), 1);
  });
}
