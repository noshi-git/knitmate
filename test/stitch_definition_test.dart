import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/models/project.dart';
import 'package:knitmate/models/stitch_definition.dart';

void main() {
  group('StitchDefinition cellBackgroundColor', () {
    test('旧JSON（cellBackgroundColorなし）を正常読込し null になる', () {
      final definition = StitchDefinition.fromJson({
        'id': 'single_crochet',
        'name': '細編み',
        'symbol': '',
        'enabled': true,
        'system': false,
        'storageIndex': 1,
      });

      expect(definition.cellBackgroundColor, isNull);
    });

    test('色ありJSONを読込し ARGB 値が一致する', () {
      const argb = 0xFFFFFF00;
      final definition = StitchDefinition.fromJson({
        'id': 'single_crochet',
        'name': '細編み',
        'symbol': '',
        'enabled': true,
        'system': false,
        'storageIndex': 1,
        'cellBackgroundColor': argb,
      });

      expect(definition.cellBackgroundColor, argb);
    });

    test('色ありDefinitionをJSON保存し再読込して色が一致する', () {
      const argb = 0xFF00BFFF;
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
        cellBackgroundColor: argb,
      );

      final json = original.toJson();
      expect(json.containsKey('cellBackgroundColor'), isTrue);
      expect(json['cellBackgroundColor'], argb);

      final restored = StitchDefinition.fromJson(json);
      expect(restored.cellBackgroundColor, argb);
    });

    test('copyWithで色を変更できる', () {
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
      );

      final updated = original.copyWith(cellBackgroundColor: 0xFFFF00FF);
      expect(updated.cellBackgroundColor, 0xFFFF00FF);
      expect(updated.id, original.id);
      expect(updated.storageIndex, original.storageIndex);
    });

    test('copyWithで色を null に戻せる', () {
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
        cellBackgroundColor: 0xFFFF00FF,
      );

      final cleared = original.copyWith(cellBackgroundColor: null);
      expect(cleared.cellBackgroundColor, isNull);
    });

    test('色なしDefinitionの toJson に cellBackgroundColor を含めない', () {
      const definition = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
      );

      expect(definition.toJson().containsKey('cellBackgroundColor'), isFalse);
    });
  });

  group('StitchDefinition shortcutKey', () {
    test('旧JSON（shortcutKeyなし）を正常読込し null になる', () {
      final definition = StitchDefinition.fromJson({
        'id': 'single_crochet',
        'name': '細編み',
        'symbol': '',
        'enabled': true,
        'system': false,
        'storageIndex': 1,
      });

      expect(definition.shortcutKey, isNull);
    });

    test('shortcutKeyありJSONを正常読込する', () {
      final definition = StitchDefinition.fromJson({
        'id': 'single_crochet',
        'name': '細編み',
        'symbol': '',
        'enabled': true,
        'system': false,
        'storageIndex': 1,
        'shortcutKey': '1',
      });

      expect(definition.shortcutKey, '1');
    });

    test('shortcutKeyありDefinitionをJSON保存し再読込して値が一致する', () {
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
        shortcutKey: 'F5',
      );

      final json = original.toJson();
      expect(json.containsKey('shortcutKey'), isTrue);
      expect(json['shortcutKey'], 'F5');

      final restored = StitchDefinition.fromJson(json);
      expect(restored.shortcutKey, 'F5');
    });

    test('copyWithでshortcutKeyを変更できる', () {
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
      );

      final updated = original.copyWith(shortcutKey: 'A');
      expect(updated.shortcutKey, 'A');
    });

    test('copyWithでshortcutKeyを null に戻せる', () {
      const original = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
        shortcutKey: 'A',
      );

      final cleared = original.copyWith(shortcutKey: null);
      expect(cleared.shortcutKey, isNull);
    });

    test('shortcutKeyなしDefinitionの toJson に shortcutKey を含めない', () {
      const definition = StitchDefinition(
        id: 'custom',
        name: 'テスト',
        symbol: 'A',
        enabled: true,
        system: false,
        storageIndex: 100,
      );

      expect(definition.toJson().containsKey('shortcutKey'), isFalse);
    });
  });

  group('Project JSON compatibility', () {
    test('既存Project JSON形式に変更がない', () {
      final project = Project(
        id: '1',
        name: 'テスト作品',
        rows: 2,
        columns: 2,
        grid: const [
          [0, 1],
          [2, 0],
        ],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final json = project.toJson();
      expect(json.keys.toSet(), {
        'id',
        'name',
        'rows',
        'columns',
        'grid',
        'createdAt',
        'updatedAt',
      });
      expect(json.containsKey('cellBackgroundColor'), isFalse);
    });

    test('storageIndex は Project grid にそのまま保持される', () {
      final project = Project.fromJson({
        'id': '1',
        'name': 'テスト作品',
        'rows': 1,
        'columns': 2,
        'grid': [
          [5, 32],
        ],
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-02T00:00:00.000',
      });

      expect(project.grid, [
        [5, 32],
      ]);
    });
  });
}
