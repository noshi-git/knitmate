// 編み記号のラベル表示方法（設定画面・選択ボタンなどで共通利用）
enum StitchLabelDisplayMode {
  /// シンボルの下に名前（初期値）
  symbolAndName,

  /// シンボルのみ
  symbolOnly,

  /// 名前のみ（将来拡張用。V4.1 UI では未提供）
  nameOnly,
}

extension StitchLabelDisplayModeX on StitchLabelDisplayMode {
  String get storageValue => name;

  String get label {
    switch (this) {
      case StitchLabelDisplayMode.symbolAndName:
        return 'シンボル＋名前';
      case StitchLabelDisplayMode.symbolOnly:
        return 'シンボルのみ';
      case StitchLabelDisplayMode.nameOnly:
        return '名前のみ';
    }
  }

  bool get showsSymbol =>
      this == StitchLabelDisplayMode.symbolAndName ||
      this == StitchLabelDisplayMode.symbolOnly;

  bool get showsName =>
      this == StitchLabelDisplayMode.symbolAndName ||
      this == StitchLabelDisplayMode.nameOnly;

  static StitchLabelDisplayMode fromStorage(String? value) {
    for (final mode in StitchLabelDisplayMode.values) {
      if (mode.storageValue == value) {
        return mode;
      }
    }
    return StitchLabelDisplayMode.symbolAndName;
  }
}
