// ユーザーが選択できる PNG シンボル表示倍率（0.25 刻み）
enum SymbolDisplayScale {
  x1_00,
  x1_25,
  x1_50,
  x1_75;

  static const SymbolDisplayScale defaultCell = x1_25;
  static const SymbolDisplayScale defaultButton = x1_50;
}

extension SymbolDisplayScaleX on SymbolDisplayScale {
  double get value {
    switch (this) {
      case SymbolDisplayScale.x1_00:
        return 1.0;
      case SymbolDisplayScale.x1_25:
        return 1.25;
      case SymbolDisplayScale.x1_50:
        return 1.5;
      case SymbolDisplayScale.x1_75:
        return 1.75;
    }
  }

  String get label {
    switch (this) {
      case SymbolDisplayScale.x1_00:
        return '1倍';
      case SymbolDisplayScale.x1_25:
        return '1.25倍';
      case SymbolDisplayScale.x1_50:
        return '1.5倍';
      case SymbolDisplayScale.x1_75:
        return '1.75倍';
    }
  }

  String get storageValue => name;

  static SymbolDisplayScale fromStorage(
    String? value, {
    SymbolDisplayScale fallback = SymbolDisplayScale.x1_25,
  }) {
    if (value == null) {
      return fallback;
    }
    for (final scale in SymbolDisplayScale.values) {
      if (scale.storageValue == value) {
        return scale;
      }
    }
    return fallback;
  }
}
