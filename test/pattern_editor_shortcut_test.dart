import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/models/stitch_definition.dart';
import 'package:knitmate/utils/stitch_shortcut_key.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const definitions = [
    StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
      shortcutKey: '1',
    ),
    StitchDefinition(
      id: 'double_crochet',
      name: '長編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 2,
      shortcutKey: '2',
    ),
  ];

  testWidgets('キーイベントで selectedStorageIndex が切り替わる', (tester) async {
    var selectedStorageIndex = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            final definition = StitchShortcutKey.findDefinitionForKeyEvent(
              definitions: definitions,
              event: event,
            );
            if (definition != null) {
              selectedStorageIndex = definition.storageIndex;
            }
            return KeyEventResult.handled;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    expect(selectedStorageIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    expect(selectedStorageIndex, 1);
  });
}
