import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lichess_mobile/src/common/errors.dart';
import 'package:lichess_mobile/src/common/http.dart';

class MockLogger extends Mock implements Logger {}

class MockClient extends Mock implements http.Client {}

void main() {
  final mockLogger = MockLogger();

  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://api.test')));
  });

  group('ApiClient', () {
    test('success responses are returned as success', () async {
      final apiClient = ApiClient(mockLogger, FakeClient());

      for (final method in [apiClient.get, apiClient.post, apiClient.delete]) {
        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/200'))
                .run(),
            isA<Right<IOError, http.Response>>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/301'))
                .run(),
            isA<Right<IOError, http.Response>>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/204'))
                .run(),
            isA<Right<IOError, http.Response>>());
      }
    });

    test('error responses are returned as error', () async {
      final apiClient = ApiClient(mockLogger, FakeClient());

      for (final method in [apiClient.get, apiClient.post, apiClient.delete]) {
        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/401'))
                .run()
                .then((r) => r.getLeft().toNullable()),
            isA<UnauthorizedError>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/403'))
                .run()
                .then((r) => r.getLeft().toNullable()),
            isA<ForbiddenError>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/404'))
                .run()
                .then((r) => r.getLeft().toNullable()),
            isA<NotFoundError>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/500'))
                .run()
                .then((r) => r.getLeft().toNullable()),
            isA<ApiRequestError>());

        expect(
            await method
                .call(Uri.parse('http://api.test/will/return/503'))
                .run()
                .then((r) => r.getLeft().toNullable()),
            isA<ApiRequestError>());
      }
    });

    test('catches socket error', () async {
      final apiClient = ApiClient(mockLogger, FakeClient());
      for (final method in [apiClient.get, apiClient.post, apiClient.delete]) {
        final resp = await method
            .call(Uri.parse('http://api.test/will/throw/socket/exception'))
            .run();
        expect(resp.getLeft().toNullable(), isA<GenericError>());
      }
    });

    test('retry on error when asked', () async {
      final mockClient = MockClient();
      final apiClient = ApiClient(mockLogger, mockClient);

      int retries = 3;

      when(() => mockClient.send(any())).thenAnswer((_) async {
        retries--;
        return retries > 0
            ? throw const SocketException('oops')
            : http.StreamedResponse(_streamBody('ok'), 200);
      });

      final resp = await apiClient
          .get(Uri.parse('http://api.test/retry'), retry: true)
          .run();

      verify(() => mockClient.send(any())).called(3);
      expect(resp, isA<Right<IOError, http.Response>>());
    });
  });
}

class FakeClient extends Fake implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _responseBasedOnPath(url.path);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _responseBasedOnPath(url.path);
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _responseBasedOnPath(url.path);
  }

  http.Response _responseBasedOnPath(String path) {
    switch (path) {
      case '/will/throw/socket/exception':
        throw const SocketException('no internet');
      case '/will/return/500':
        return http.Response('500', 500);
      case '/will/return/503':
        return http.Response('503', 503);
      case '/will/return/400':
        return http.Response('400', 400);
      case '/will/return/404':
        return http.Response('404', 404);
      case '/will/return/401':
        return http.Response('401', 401);
      case '/will/return/403':
        return http.Response('403', 403);
      case '/will/return/204':
        return http.Response('204', 204);
      case '/will/return/301':
        return http.Response('301', 301);
      default:
        return http.Response('ok', 200);
    }
  }
}

Stream<List<int>> _streamBody(String body) => Stream.value(utf8.encode(body));