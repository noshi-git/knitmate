// 編み記号マスターの1件分のデータ
class StitchDefinition {
  const StitchDefinition({
    required this.id,
    required this.name,
    required this.symbol,
    required this.enabled,
    required this.system,
    required this.storageIndex,
  });

  // 永続ID（例: empty, single_crochet）
  final String id;

  // 名称（選択ボタンなどに表示）
  final String name;

  // セル内に表示する記号
  final String symbol;

  // 有効 / 無効（削除ではなく無効化で運用）
  final bool enabled;

  // システム定義（true は空白のみ。編集・無効化不可）
  final bool system;

  // 作品JSONに保存する永続番号（旧 StitchSymbol.index と互換）
  final int storageIndex;

  // 初期記号の storageIndex（既存作品との互換のため固定）
  static const int emptyStorageIndex = 0;
  static const int singleCrochetStorageIndex = 1;
  static const int doubleCrochetStorageIndex = 2;
  static const int trebleCrochetStorageIndex = 3;
  static const int slipStitchStorageIndex = 4;
  static const int chainStorageIndex = 5;
  static const int halfDoubleCrochetStorageIndex = 6;
  static const int singleCrochetInc2StorageIndex = 7;
  static const int singleCrochetInc3StorageIndex = 8;
  static const int singleCrochetDec2StorageIndex = 9;
  static const int halfDoubleCrochetInc2StorageIndex = 10;
  static const int halfDoubleCrochetDec2StorageIndex = 11;
  static const int doubleCrochetInc2StorageIndex = 12;
  static const int doubleCrochetDec2StorageIndex = 13;
  static const int trebleCrochetInc2StorageIndex = 14;
  static const int trebleCrochetDec2StorageIndex = 15;
  static const int singleCrochetFrontPostStorageIndex = 16;
  static const int singleCrochetBackPostStorageIndex = 17;
  static const int singleCrochetCh1SingleCrochetStorageIndex = 18;
  static const int singleCrochetCh2SingleCrochetStorageIndex = 19;
  static const int ribSingleCrochetStorageIndex = 20;
  static const int reverseSingleCrochetStorageIndex = 21;
  static const int twistedSingleCrochetStorageIndex = 22;
  static const int picotStorageIndex = 23;
  static const int halfDoubleCrochetCluster3StorageIndex = 24;
  static const int halfDoubleCrochetFrontPostStorageIndex = 25;
  static const int halfDoubleCrochetBackPostStorageIndex = 26;
  static const int crossedDoubleCrochetStorageIndex = 27;
  static const int doubleCrochetCluster3StorageIndex = 28;
  static const int doubleCrochetPopcorn5StorageIndex = 29;

  // ユーザー追加用のIDを生成する
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'enabled': enabled,
      'system': system,
      'storageIndex': storageIndex,
    };
  }

  factory StitchDefinition.fromJson(Map<String, dynamic> json) {
    return StitchDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      enabled: json['enabled'] as bool,
      system: json['system'] as bool,
      // 旧形式（storageIndex なし）は -1 として読み込み、後で移行する
      storageIndex: json['storageIndex'] as int? ?? -1,
    );
  }

  StitchDefinition copyWith({
    String? id,
    String? name,
    String? symbol,
    bool? enabled,
    bool? system,
    int? storageIndex,
  }) {
    return StitchDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      enabled: enabled ?? this.enabled,
      system: system ?? this.system,
      storageIndex: storageIndex ?? this.storageIndex,
    );
  }
}
