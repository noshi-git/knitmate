import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/models/stitch_definition.dart';
import 'package:knitmate/utils/stitch_shortcut_key.dart';

void main() {
  group('StitchShortcutKey normalize', () {
    test('a を A に正規化する', () {
      expect(StitchShortcutKey.normalize('a'), 'A');
      expect(StitchShortcutKey.normalize('A'), 'A');
    });

    test('f5 を F5 に正規化する', () {
      expect(StitchShortcutKey.normalize('f5'), 'F5');
      expect(StitchShortcutKey.normalize('F5'), 'F5');
    });

    test('未対応文字列は null になる', () {
      expect(StitchShortcutKey.normalize('Ctrl'), isNull);
      expect(StitchShortcutKey.normalize(''), isNull);
    });
  });

  group('StitchShortcutKey duplicate detection', () {
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
      ),
    ];

    test('重複キーを検出する', () {
      final duplicate = StitchShortcutKey.findDuplicateOwner(
        definitions: definitions,
        shortcutKey: '1',
        excludeDefinitionId: 'double_crochet',
      );

      expect(duplicate?.name, '細編み');
    });

    test('自分自身は重複対象外', () {
      final duplicate = StitchShortcutKey.findDuplicateOwner(
        definitions: definitions,
        shortcutKey: '1',
        excludeDefinitionId: 'single_crochet',
      );

      expect(duplicate, isNull);
    });
  });

  group('StitchShortcutKey selection', () {
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
        enabled: false,
        system: false,
        storageIndex: 2,
        shortcutKey: '2',
      ),
      StitchDefinition(
        id: 'empty',
        name: '空白',
        symbol: '',
        enabled: true,
        system: true,
        storageIndex: 0,
        shortcutKey: '0',
      ),
    ];

    test('disabled 記号はショートカット対象外', () {
      final definition = StitchShortcutKey.findDefinitionForShortcutKey(
        definitions: definitions,
        shortcutKey: '2',
      );

      expect(definition, isNull);
    });

    test('system 記号はショートカット対象外', () {
      final definition = StitchShortcutKey.findDefinitionForShortcutKey(
        definitions: definitions,
        shortcutKey: '0',
      );

      expect(definition, isNull);
    });

    test('有効な記号を shortcutKey で取得できる', () {
      final definition = StitchShortcutKey.findDefinitionForShortcutKey(
        definitions: definitions,
        shortcutKey: '1',
      );

      expect(definition?.storageIndex, 1);
    });
  });

  group('StitchShortcutKey forbidden keys', () {
    test('修飾キー単体は登録できない', () {
      expect(
        StitchShortcutKey.fromLogicalKey(LogicalKeyboardKey.shiftLeft),
        isNull,
      );
      expect(
        StitchShortcutKey.fromLogicalKey(LogicalKeyboardKey.controlLeft),
        isNull,
      );
    });

    test('矢印キーは登録できない', () {
      expect(
        StitchShortcutKey.fromLogicalKey(LogicalKeyboardKey.arrowUp),
        isNull,
      );
    });
  });
}
