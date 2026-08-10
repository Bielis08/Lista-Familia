import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

String _releaseJson({
  String tagName = 'v2.6.0',
  String? body = 'Notas de la version',
  bool includeApk = true,
}) {
  return jsonEncode({
    'tag_name': tagName,
    'body': body,
    'assets': includeApk
        ? [
            {
              'name': 'lista-familia.apk',
              'browser_download_url': 'https://example.com/lista-familia.apk',
              'id': 12345,
            },
          ]
        : <Object>[],
  });
}

ResponseBody _jsonResponse(String body, {int status = 200}) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {Headers.contentTypeHeader: ['application/json']},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Lista Familia',
      packageName: 'com.example.lista_familia',
      version: '2.5.0',
      buildNumber: '4',
      buildSignature: '',
    );
    tempDir = Directory.systemTemp.createTempSync('update_service_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('isNewerVersion', () {
    test('returns true for a newer patch version', () {
      expect(UpdateService.isNewerVersion('2.6.0', '2.5.9'), isTrue);
    });

    test('returns false for the same version', () {
      expect(UpdateService.isNewerVersion('2.6.0', '2.6.0'), isFalse);
    });

    test('returns false for an older version', () {
      expect(UpdateService.isNewerVersion('2.6.0', '2.6.1'), isFalse);
    });

    test('compares numerically, not lexically', () {
      expect(UpdateService.isNewerVersion('2.10.0', '2.9.0'), isTrue);
    });

    test('handles leading v prefix', () {
      expect(UpdateService.isNewerVersion('v2.6.0', '2.5.0'), isTrue);
      expect(UpdateService.isNewerVersion('V2.6.0', '2.5.0'), isTrue);
    });

    test('pads missing segments with zero', () {
      expect(UpdateService.isNewerVersion('2.6', '2.6.0'), isFalse);
      expect(UpdateService.isNewerVersion('2.6', '2.5.9'), isTrue);
    });

    test('prerelease is not newer than the same stable version', () {
      expect(UpdateService.isNewerVersion('2.6.0-beta.1', '2.6.0'), isFalse);
    });

    test('stable is newer than the same prerelease', () {
      expect(UpdateService.isNewerVersion('2.6.0', '2.6.0-beta.1'), isTrue);
    });

    test('prerelease of a newer version is newer', () {
      expect(UpdateService.isNewerVersion('2.7.0-rc.1', '2.6.0'), isTrue);
    });

    test('ignores build metadata', () {
      expect(UpdateService.isNewerVersion('2.6.0+7', '2.6.0+5'), isFalse);
      expect(UpdateService.isNewerVersion('2.6.0', '2.5.0+100'), isTrue);
    });

    test('returns false for unparsable versions', () {
      expect(UpdateService.isNewerVersion('not-a-version', '2.5.0'), isFalse);
      expect(UpdateService.isNewerVersion('', '2.5.0'), isFalse);
    });
  });

  group('checkForUpdate', () {
    test('returns updateAvailable with parsed release', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter((_) async => _jsonResponse(_releaseJson()));
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.updateAvailable);
      expect(result.release, isNotNull);
      expect(result.release!.version, '2.6.0');
      expect(result.release!.apkUrl, 'https://example.com/lista-familia.apk');
      expect(result.release!.assetId, '12345');
      expect(result.release!.releaseNote, 'Notas de la version');
    });

    test('returns upToDate when version matches current', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Lista Familia',
        packageName: 'com.example.lista_familia',
        version: '2.6.0',
        buildNumber: '5',
        buildSignature: '',
      );
      final dio = Dio()..httpClientAdapter = _FakeAdapter((_) async => _jsonResponse(_releaseJson()));
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.upToDate);
      expect(result.release, isNull);
    });

    test('returns upToDate when remote version is older', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => _jsonResponse(_releaseJson(tagName: 'v2.4.0')),
      );
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.upToDate);
    });

    test('returns error on non-200 response', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => _jsonResponse('{"message": "rate limited"}', status: 403),
      );
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.error);
    });

    test('returns error when no apk asset is present', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => _jsonResponse(_releaseJson(includeApk: false)),
      );
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.error);
    });

    test('returns error when request throws', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/'),
          reason: 'network down',
        ),
      );
      final service = UpdateService.forTesting(dio);

      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.error);
    });
  });

  group('downloadApk', () {
    test('downloads and stores the file atomically', () async {
      final bytes = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => ResponseBody.fromBytes(bytes, 200),
      );
      final service = UpdateService.forTesting(dio);

      final path = await service.downloadApk(
        'https://example.com/app.apk',
        overrideDirectory: tempDir.path,
      );

      expect(path, isNotNull);
      final file = File(path!);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), 1024);
      expect(path.endsWith('.apk'), isTrue);
    });

    test('reports download progress', () async {
      final bytes = Uint8List.fromList(List<int>.filled(2048, 1));
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => ResponseBody.fromBytes(
          bytes,
          200,
          headers: {'content-length': [bytes.length.toString()]},
        ),
      );
      final service = UpdateService.forTesting(dio);

      final progressValues = <double>[];
      await service.downloadApk(
        'https://example.com/app.apk',
        overrideDirectory: tempDir.path,
        onProgress: progressValues.add,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, greaterThan(0));
    });

    test('returns null and cleans up on error', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/'),
          reason: 'download failed',
        ),
      );
      final service = UpdateService.forTesting(dio);

      final path = await service.downloadApk(
        'https://example.com/app.apk',
        overrideDirectory: tempDir.path,
      );

      expect(path, isNull);
      final leftovers = tempDir.listSync().whereType<File>().toList();
      expect(leftovers, isEmpty);
    });

    test('returns null when download is incomplete (empty body)', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(
        (_) async => ResponseBody.fromBytes(Uint8List(0), 200),
      );
      final service = UpdateService.forTesting(dio);

      final path = await service.downloadApk(
        'https://example.com/app.apk',
        overrideDirectory: tempDir.path,
      );

      expect(path, isNull);
      final leftovers = tempDir.listSync().whereType<File>().toList();
      expect(leftovers, isEmpty);
    });
  });
}
