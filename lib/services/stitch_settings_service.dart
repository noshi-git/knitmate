import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/stitch_definition.dart';

// 編み記号マスターをJSONファイルで保存・読み込みする
class StitchSettingsService {
  static const String _definitionsFilePath = 'KnitMate/stitch_definitions.json';

  // 初期5種類の storageIndex（旧 StitchSymbol.index と一致）
  static const Map<String, int> _systemStorageIndexes = {
    'empty': StitchDefinition.emptyStorageIndex,
    'single_crochet': StitchDefinition.singleCrochetStorageIndex,
    'double_crochet': StitchDefinition.doubleCrochetStorageIndex,
    'treble_crochet': StitchDefinition.trebleCrochetStorageIndex,
    'slip_stitch': StitchDefinition.slipStitchStorageIndex,
  };

  // 保存先ファイルを取得する（フォルダがなければ作成）
  Future<File> _getDefinitionsFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$_definitionsFilePath');
    final directory = file.parent;

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return file;
  }

  // 次に割り当てる storageIndex を求める（最大値 + 1）
  static int nextStorageIndex(List<StitchDefinition> definitions) {
    var maxIndex = -1;
    for (final definition in definitions) {
      if (definition.storageIndex > maxIndex) {
        maxIndex = definition.storageIndex;
      }
    }
    return maxIndex + 1;
  }

  // 初回起動時に使うデフォルトの編み記号一覧
  List<StitchDefinition> _createDefaultDefinitions() {
    return const [
      StitchDefinition(
        id: 'empty',
        name: '空白',
        symbol: '',
        enabled: true,
        system: true,
        storageIndex: StitchDefinition.emptyStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet',
        name: '細編み',
        symbol: '×',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet',
        name: '長編み',
        symbol: 'T',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'treble_crochet',
        name: '長々編み',
        symbol: 'TT',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.trebleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'slip_stitch',
        name: '引き抜き編み',
        symbol: '●',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.slipStitchStorageIndex,
      ),
    ];
  }

  // 旧形式（storageIndex なし）の定義を新形式へ移行する
  List<StitchDefinition> _migrateDefinitions(List<StitchDefinition> definitions) {
    final usedIndexes = <int>{};
    final migrated = <StitchDefinition>[];

    for (final definition in definitions) {
      if (definition.storageIndex >= 0) {
        usedIndexes.add(definition.storageIndex);
      }
    }

    var nextCustomIndex = usedIndexes.isEmpty
        ? StitchDefinition.slipStitchStorageIndex + 1
        : usedIndexes.reduce((a, b) => a > b ? a : b) + 1;

    for (final definition in definitions) {
      if (definition.storageIndex >= 0) {
        migrated.add(definition);
        continue;
      }

      final systemIndex = _systemStorageIndexes[definition.id];
      if (systemIndex != null) {
        migrated.add(definition.copyWith(storageIndex: systemIndex));
        usedIndexes.add(systemIndex);
        continue;
      }

      while (usedIndexes.contains(nextCustomIndex)) {
        nextCustomIndex++;
      }

      migrated.add(definition.copyWith(storageIndex: nextCustomIndex));
      usedIndexes.add(nextCustomIndex);
      nextCustomIndex++;
    }

    return migrated;
  }

  // storageIndex の移行が必要か
  bool _needsMigration(List<StitchDefinition> definitions) {
    return definitions.any((definition) => definition.storageIndex < 0);
  }

  // 編み記号マスターを読み込む（JSONがなければ初期データを生成して保存）
  Future<List<StitchDefinition>> loadDefinitions() async {
    final file = await _getDefinitionsFile();

    if (!await file.exists()) {
      final defaults = _createDefaultDefinitions();
      await saveDefinitions(defaults);
      return List<StitchDefinition>.from(defaults);
    }

    try {
      final jsonText = await file.readAsString();
      final decoded = jsonDecode(jsonText);

      if (decoded is List<dynamic>) {
        final definitions = decoded
            .map(
              (item) => StitchDefinition.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        if (_needsMigration(definitions)) {
          final migrated = _migrateDefinitions(definitions);
          await saveDefinitions(migrated);
          return migrated;
        }

        return definitions;
      }
    } catch (_) {
      // 不正なJSONの場合は初期データで上書きする
    }

    final defaults = _createDefaultDefinitions();
    await saveDefinitions(defaults);
    return List<StitchDefinition>.from(defaults);
  }

  // 編み記号マスターをJSONファイルに保存する
  Future<void> saveDefinitions(List<StitchDefinition> definitions) async {
    final file = await _getDefinitionsFile();
    final jsonList = definitions.map((definition) => definition.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
