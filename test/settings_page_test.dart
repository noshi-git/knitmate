import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/screens/settings_page.dart';
import 'package:knitmate/services/stitch_display_settings_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'KnitMate',
      packageName: 'knitmate',
      version: '4.1.0',
      buildNumber: '2',
      buildSignature: '',
    );
    await StitchDisplaySettingsService.instance.load();
  });

  testWidgets('設定画面に pubspec の version が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KnitMate Version 4.1.0'), findsOneWidget);
  });
}
