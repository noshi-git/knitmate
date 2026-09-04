import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/main.dart';
import 'package:knitmate/services/stitch_display_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ホーム画面が表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StitchDisplaySettingsService.instance.load();

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('KnitMate'), findsOneWidget);
    expect(find.text('作品一覧'), findsOneWidget);
  });
}
