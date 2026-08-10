import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/stitch_definition.dart';

// 編み記号マスターをJSONファイルで保存・読み込みする
class StitchSettingsService {
  static const String _definitionsFilePath = 'KnitMate/stitch_definitions.json';

  // 初期公式記号の storageIndex（旧 StitchSymbol.index と一致する分は固定）
  static const Map<String, int> _systemStorageIndexes = {
    'empty': StitchDefinition.emptyStorageIndex,
    'single_crochet': StitchDefinition.singleCrochetStorageIndex,
    'double_crochet': StitchDefinition.doubleCrochetStorageIndex,
    'treble_crochet': StitchDefinition.trebleCrochetStorageIndex,
    'slip_stitch': StitchDefinition.slipStitchStorageIndex,
    'chain': StitchDefinition.chainStorageIndex,
    'half_double_crochet': StitchDefinition.halfDoubleCrochetStorageIndex,
    'single_crochet_inc2': StitchDefinition.singleCrochetInc2StorageIndex,
    'single_crochet_inc3': StitchDefinition.singleCrochetInc3StorageIndex,
    'single_crochet_dec2': StitchDefinition.singleCrochetDec2StorageIndex,
    'half_double_crochet_inc2':
        StitchDefinition.halfDoubleCrochetInc2StorageIndex,
    'half_double_crochet_dec2':
        StitchDefinition.halfDoubleCrochetDec2StorageIndex,
    'double_crochet_inc2': StitchDefinition.doubleCrochetInc2StorageIndex,
    'double_crochet_dec2': StitchDefinition.doubleCrochetDec2StorageIndex,
    'treble_crochet_inc2': StitchDefinition.trebleCrochetInc2StorageIndex,
    'treble_crochet_dec2': StitchDefinition.trebleCrochetDec2StorageIndex,
    'single_crochet_front_post':
        StitchDefinition.singleCrochetFrontPostStorageIndex,
    'single_crochet_back_post':
        StitchDefinition.singleCrochetBackPostStorageIndex,
    'single_crochet_ch1_single_crochet':
        StitchDefinition.singleCrochetCh1SingleCrochetStorageIndex,
    'single_crochet_ch2_single_crochet':
        StitchDefinition.singleCrochetCh2SingleCrochetStorageIndex,
    'rib_single_crochet': StitchDefinition.ribSingleCrochetStorageIndex,
    'reverse_single_crochet':
        StitchDefinition.reverseSingleCrochetStorageIndex,
    'twisted_single_crochet':
        StitchDefinition.twistedSingleCrochetStorageIndex,
    'picot': StitchDefinition.picotStorageIndex,
    'half_double_crochet_cluster3':
        StitchDefinition.halfDoubleCrochetCluster3StorageIndex,
    'half_double_crochet_front_post':
        StitchDefinition.halfDoubleCrochetFrontPostStorageIndex,
    'half_double_crochet_back_post':
        StitchDefinition.halfDoubleCrochetBackPostStorageIndex,
    'crossed_double_crochet':
        StitchDefinition.crossedDoubleCrochetStorageIndex,
    'double_crochet_cluster3':
        StitchDefinition.doubleCrochetCluster3StorageIndex,
    'double_crochet_popcorn5':
        StitchDefinition.doubleCrochetPopcorn5StorageIndex,
    'double_crochet_front_post':
        StitchDefinition.doubleCrochetFrontPostStorageIndex,
    'double_crochet_back_post':
        StitchDefinition.doubleCrochetBackPostStorageIndex,
    'ring_stitch': StitchDefinition.ringStitchStorageIndex,
    'double_crochet_shell5_in_stitch':
        StitchDefinition.doubleCrochetShell5InStitchStorageIndex,
    'double_crochet_shell5_over_stitches':
        StitchDefinition.doubleCrochetShell5OverStitchesStorageIndex,
    'attach_yarn': StitchDefinition.attachYarnStorageIndex,
    'cut_yarn': StitchDefinition.cutYarnStorageIndex,
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

  /// 開発用カタログ向け: 公式36記号（empty を除く）を返す
  List<StitchDefinition> officialCatalogDefinitions() {
    return _createDefaultDefinitions()
        .where((definition) => definition.id != 'empty')
        .toList(growable: false);
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
        id: 'chain',
        name: 'くさり編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.chainStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet',
        name: 'こま編み/細編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_inc2',
        name: 'こま編み2目編み入れる（1目増目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetInc2StorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_inc3',
        name: 'こま編み3目編み入れる（2目増目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetInc3StorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_dec2',
        name: 'こま編み2目一度（1目減目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetDec2StorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_front_post',
        name: 'こま編み表引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetFrontPostStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_back_post',
        name: 'こま編み裏引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.singleCrochetBackPostStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_ch1_single_crochet',
        name: 'こま編み1、くさり1、こま編み1',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex:
            StitchDefinition.singleCrochetCh1SingleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'single_crochet_ch2_single_crochet',
        name: 'こま編み1、くさり2、こま編み1',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex:
            StitchDefinition.singleCrochetCh2SingleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'rib_single_crochet',
        name: 'すじ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.ribSingleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'reverse_single_crochet',
        name: 'バックこま編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.reverseSingleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'twisted_single_crochet',
        name: 'ねじりこま編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.twistedSingleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'picot',
        name: 'ピコット編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.picotStorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet',
        name: '中長編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet_inc2',
        name: '中長編み2目編み入れる（1目増目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetInc2StorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet_dec2',
        name: '中長編み2目一度（1目減目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetDec2StorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet_cluster3',
        name: '中長編み3目の玉編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetCluster3StorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet_front_post',
        name: '中長編み表引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetFrontPostStorageIndex,
      ),
      StitchDefinition(
        id: 'half_double_crochet_back_post',
        name: '中長編み裏引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.halfDoubleCrochetBackPostStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet',
        name: '長編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_inc2',
        name: '長編み2目編み入れる（1目増目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetInc2StorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_dec2',
        name: '長編み2目一度（1目減目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetDec2StorageIndex,
      ),
      StitchDefinition(
        id: 'crossed_double_crochet',
        name: '長編み交差',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.crossedDoubleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_cluster3',
        name: '長編み3目の玉編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetCluster3StorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_popcorn5',
        name: '長編み5目のポップコーン編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetPopcorn5StorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_front_post',
        name: '長編み表引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetFrontPostStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_back_post',
        name: '長編み裏引き上げ編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetBackPostStorageIndex,
      ),
      StitchDefinition(
        id: 'treble_crochet',
        name: '長々編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.trebleCrochetStorageIndex,
      ),
      StitchDefinition(
        id: 'treble_crochet_inc2',
        name: '長々編み2目編み入れる（1目増目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.trebleCrochetInc2StorageIndex,
      ),
      StitchDefinition(
        id: 'treble_crochet_dec2',
        name: '長々編み2目一度（1目減目）',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.trebleCrochetDec2StorageIndex,
      ),
      StitchDefinition(
        id: 'ring_stitch',
        name: 'リング編み',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.ringStitchStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_shell5_in_stitch',
        name: '長編み5目を前段の1目に編み入れる',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.doubleCrochetShell5InStitchStorageIndex,
      ),
      StitchDefinition(
        id: 'double_crochet_shell5_over_stitches',
        name: '前段の目を束にすくって長編み5目編む',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex:
            StitchDefinition.doubleCrochetShell5OverStitchesStorageIndex,
      ),
      StitchDefinition(
        id: 'attach_yarn',
        name: '糸をつける',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.attachYarnStorageIndex,
      ),
      StitchDefinition(
        id: 'cut_yarn',
        name: '糸を切る',
        symbol: '',
        enabled: true,
        system: false,
        storageIndex: StitchDefinition.cutYarnStorageIndex,
      ),
      StitchDefinition(
        id: 'slip_stitch',
        name: '引き抜き編み',
        symbol: '',
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
        ? StitchDefinition.cutYarnStorageIndex + 1
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

  // 公式記号が欠けていれば追加する
  List<StitchDefinition> _mergeOfficialDefinitions(
    List<StitchDefinition> definitions,
  ) {
    final byId = {for (final item in definitions) item.id: item};
    final usedIndexes = {
      for (final item in definitions) item.storageIndex,
    };
    final merged = List<StitchDefinition>.from(definitions);
    var changed = false;

    for (final official in _createDefaultDefinitions()) {
      if (byId.containsKey(official.id)) {
        continue;
      }

      var storageIndex = official.storageIndex;
      if (usedIndexes.contains(storageIndex)) {
        storageIndex = nextStorageIndex(merged);
      }

      merged.add(official.copyWith(storageIndex: storageIndex));
      usedIndexes.add(storageIndex);
      byId[official.id] = official;
      changed = true;
    }

    if (!changed) {
      return definitions;
    }
    return merged;
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
        var definitions = decoded
            .map(
              (item) => StitchDefinition.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        var needsSave = false;

        if (_needsMigration(definitions)) {
          definitions = _migrateDefinitions(definitions);
          needsSave = true;
        }

        final merged = _mergeOfficialDefinitions(definitions);
        if (!identical(merged, definitions)) {
          definitions = merged;
          needsSave = true;
        }

        if (needsSave) {
          await saveDefinitions(definitions);
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
