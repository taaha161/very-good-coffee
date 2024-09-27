import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:coffee_app_vgv/repository/image_repo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'unit_test.mocks.dart';

// Generate mocks for Dio and SharedPreferences
@GenerateMocks([Dio, SharedPreferences, http.Client])
void main() {
  late MockDio mockDio;
  late MockSharedPreferences mockSharedPreferences;
  late ImageRepository imageRepo;
  late MockClient mockClient;

  const favoriteImagesListK = 'favoriteImagesList';
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return kTemporaryPath;
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
    return kTemporaryPath;
  });

// Setting up my very good tests
  setUp(() {
    mockDio = MockDio();
    mockSharedPreferences = MockSharedPreferences();
    imageRepo = ImageRepository();
    PathProviderPlatform.instance = MockPathProviderPlatform();
    mockClient = MockClient();
  });

  group('saveImageToLocal', () {
    test('should save image to local and return file path on success',
        () async {
      final testDirectory = await getTemporaryDirectory();
      const imageUrl = 'https://coffee.alexflipnote.dev/RFLghuMJqIo_coffee.png';
      final fileName = imageUrl.split('/').last;
      final filePath = '${testDirectory.path}/$fileName';

      // Mock the Dio download response
      when(mockDio.download(imageUrl, filePath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: imageUrl),
          statusCode: 200,
        ),
      );
      when(mockSharedPreferences.getStringList(favoriteImagesListK))
          .thenReturn([]);
      when(mockSharedPreferences.setStringList(favoriteImagesListK, [filePath]))
          .thenAnswer((_) async => true);

      // Call the function and verify the results
      final result = await imageRepo.saveImageToLocal(
        imageUrl,
        dio: mockDio,
        sharedPreferences: mockSharedPreferences,
        localDirectory: testDirectory,
      );

      expect(result, filePath);
      verify(mockDio.download(imageUrl, filePath)).called(1);
    });

    test('should log error and return null if download fails', () async {
      final testDirectory = await getTemporaryDirectory();
      final imageUrl = 'https://example.com/image.png';
      final fileName = imageUrl.split('/').last;
      final filePath = '${testDirectory.path}/$fileName';

      // Mock the Dio download response to simulate failure
      when(mockDio.download(imageUrl, filePath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: imageUrl),
          statusCode: 404,
        ),
      );
      when(mockSharedPreferences.getStringList(favoriteImagesListK))
          .thenReturn([]);
      when(mockSharedPreferences.setStringList(favoriteImagesListK, [filePath]))
          .thenAnswer((_) async => true);

      // Call the function and verify the results
      final result = await imageRepo.saveImageToLocal(
        imageUrl,
        dio: mockDio,
        sharedPreferences: mockSharedPreferences,
        localDirectory: testDirectory,
      );

      expect(result, null);
      verify(mockDio.download(imageUrl, filePath)).called(1);
    });
  });

  group('getFavoriteImagePaths', () {
    test('should return list of saved image paths', () async {
      final expectedPaths = ['path1', 'path2'];

      // Mock SharedPreferences response
      when(mockSharedPreferences.getStringList(favoriteImagesListK))
          .thenReturn(expectedPaths);

      // Call the function and verify the results
      final result =
          await imageRepo.getFavoriteImagePaths(perfs: mockSharedPreferences);

      expect(result, expectedPaths);
      verify(mockSharedPreferences.getStringList(favoriteImagesListK))
          .called(1);
    });

    test('should return null when no image paths are saved', () async {
      // Mock SharedPreferences response to return null
      when(mockSharedPreferences.getStringList(favoriteImagesListK))
          .thenReturn(null);

      // Call the function and verify the results
      final result =
          await imageRepo.getFavoriteImagePaths(perfs: mockSharedPreferences);

      expect(result, null);
      verify(mockSharedPreferences.getStringList(favoriteImagesListK))
          .called(1);
    });
  });

  group('fetchNetworkImages', () {
    test('should load a list of images on successful response', () async {
      const jsonResponse =
          '{"file": "https://coffee.alexflipnote.dev/image.png"}';

      // Mocking the http get response
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      // Call the function and inject the mock client
      final result = await imageRepo.loadNetworkImage(client: mockClient);

      // Assertions
      expect(result, isNotNull);
      expect(result!.length, 10); // Expecting 10 images
      verify(mockClient.get(any))
          .called(10); // Verify that the GET request was called 10 times
    });

    test('should return null on non-200 response', () async {
      // Mock a non-200 response
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Error', 404),
      );

      final result = await imageRepo.loadNetworkImage(client: mockClient);

      // Assertions
      expect(result, isNull);
      verify(mockClient.get(any))
          .called(1); // Verify it stops after the first failed request
    });

    test('should return null on SocketException', () async {
      // Mock a SocketException
      when(mockClient.get(any)).thenThrow(SocketException('Failed to connect'));

      final result = await imageRepo.loadNetworkImage(client: mockClient);

      // Assertions
      expect(result, isNull);
      verify(mockClient.get(any)).called(1); // Verify it stops on exception
    });

    test('should return null on TimeoutException', () async {
      // Mock a TimeoutException
      when(mockClient.get(any))
          .thenThrow(TimeoutException('Request timed out'));

      final result = await imageRepo.loadNetworkImage(client: mockClient);

      // Assertions
      expect(result, isNull);
      verify(mockClient.get(any)).called(1); // Verify it stops on exception
    });
  });
}