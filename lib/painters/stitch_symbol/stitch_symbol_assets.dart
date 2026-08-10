import '../../models/stitch_symbol_type.dart';

/// 公式36記号の PNG アセットパスを解決する。
class StitchSymbolAssets {
  StitchSymbolAssets._();

  static const _root = 'assets/symbols';

  /// 公式 Type 向け PNG パス。empty / unknown は null。
  static String? assetPathFor(StitchSymbolType type) {
    final id = StitchSymbolTypeMapper.idFor(type);
    if (id == null || id == 'empty') {
      return null;
    }
    return '$_root/$id.png';
  }

  /// [StitchDefinition.id] 向け PNG パス。
  static String? assetPathForId(String id) {
    return assetPathFor(StitchSymbolTypeMapper.fromId(id));
  }

  static bool hasAsset(StitchSymbolType type) => assetPathFor(type) != null;
}
