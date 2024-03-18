import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:first_project/main.dart';
import 'package:path/path.dart' as p;

class MockHttpClient extends Mock implements http.Client {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MainScreen', () {
    late MainScreen mainScreen;
    late MockHttpClient mockHttpClient;
    late Directory appDocumentsDirectory;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      appDocumentsDirectory = await getApplicationDocumentsDirectory();
      TestWidgetsFlutterBinding.ensureInitialized();

      when(mockHttpClient.post(Uri.parse('https://your-api-endpoint.com'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'data': 'response'}), 200));

      final imageItemsDatabasePath = p.join(appDocumentsDirectory.path, 'images.db');
      await deleteDatabase(imageItemsDatabasePath);

      mainScreen = MainScreen(
        httpClient: mockHttpClient,
      );


    });

    testWidgets('displays a list of image items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: mainScreen,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(1));
    });

    testWidgets('navigates to the details screen when an image item is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: mainScreen,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(DetailsScreen), findsOneWidget);
    });

    testWidgets('creates a new image item when the floating action button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: mainScreen,
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test prompt');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}