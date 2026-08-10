// 公式編み記号の種類（Step1〜Step5 / 公式36種）
enum StitchSymbolType {
  empty,

  // Step1
  chain,
  slipStitch,
  singleCrochet,

  // Step2
  halfDoubleCrochet,
  doubleCrochet,
  trebleCrochet,

  // Step3
  singleCrochetInc2,
  singleCrochetInc3,
  singleCrochetDec2,
  halfDoubleCrochetInc2,
  halfDoubleCrochetDec2,
  doubleCrochetInc2,
  doubleCrochetDec2,
  trebleCrochetInc2,
  trebleCrochetDec2,

  // Step4
  singleCrochetFrontPost,
  singleCrochetBackPost,
  singleCrochetCh1SingleCrochet,
  singleCrochetCh2SingleCrochet,
  ribSingleCrochet,
  reverseSingleCrochet,
  twistedSingleCrochet,
  picot,
  halfDoubleCrochetCluster3,
  halfDoubleCrochetFrontPost,
  halfDoubleCrochetBackPost,
  crossedDoubleCrochet,
  doubleCrochetCluster3,
  doubleCrochetPopcorn5,

  // Step5
  doubleCrochetFrontPost,
  doubleCrochetBackPost,
  ringStitch,
  doubleCrochetShell5InStitch,
  doubleCrochetShell5OverStitches,
  attachYarn,
  cutYarn,

  /// 公式マップにない id。文字描画へフォールバックする
  unknown,
}

// StitchDefinition.id と StitchSymbolType の相互変換
class StitchSymbolTypeMapper {
  StitchSymbolTypeMapper._();

  static const Map<String, StitchSymbolType> _idToType = {
    'empty': StitchSymbolType.empty,
    'chain': StitchSymbolType.chain,
    'slip_stitch': StitchSymbolType.slipStitch,
    'single_crochet': StitchSymbolType.singleCrochet,
    'half_double_crochet': StitchSymbolType.halfDoubleCrochet,
    'double_crochet': StitchSymbolType.doubleCrochet,
    'treble_crochet': StitchSymbolType.trebleCrochet,
    'single_crochet_inc2': StitchSymbolType.singleCrochetInc2,
    'single_crochet_inc3': StitchSymbolType.singleCrochetInc3,
    'single_crochet_dec2': StitchSymbolType.singleCrochetDec2,
    'half_double_crochet_inc2': StitchSymbolType.halfDoubleCrochetInc2,
    'half_double_crochet_dec2': StitchSymbolType.halfDoubleCrochetDec2,
    'double_crochet_inc2': StitchSymbolType.doubleCrochetInc2,
    'double_crochet_dec2': StitchSymbolType.doubleCrochetDec2,
    'treble_crochet_inc2': StitchSymbolType.trebleCrochetInc2,
    'treble_crochet_dec2': StitchSymbolType.trebleCrochetDec2,
    'single_crochet_front_post': StitchSymbolType.singleCrochetFrontPost,
    'single_crochet_back_post': StitchSymbolType.singleCrochetBackPost,
    'single_crochet_ch1_single_crochet':
        StitchSymbolType.singleCrochetCh1SingleCrochet,
    'single_crochet_ch2_single_crochet':
        StitchSymbolType.singleCrochetCh2SingleCrochet,
    'rib_single_crochet': StitchSymbolType.ribSingleCrochet,
    'reverse_single_crochet': StitchSymbolType.reverseSingleCrochet,
    'twisted_single_crochet': StitchSymbolType.twistedSingleCrochet,
    'picot': StitchSymbolType.picot,
    'half_double_crochet_cluster3': StitchSymbolType.halfDoubleCrochetCluster3,
    'half_double_crochet_front_post':
        StitchSymbolType.halfDoubleCrochetFrontPost,
    'half_double_crochet_back_post': StitchSymbolType.halfDoubleCrochetBackPost,
    'crossed_double_crochet': StitchSymbolType.crossedDoubleCrochet,
    'double_crochet_cluster3': StitchSymbolType.doubleCrochetCluster3,
    'double_crochet_popcorn5': StitchSymbolType.doubleCrochetPopcorn5,
    'double_crochet_front_post': StitchSymbolType.doubleCrochetFrontPost,
    'double_crochet_back_post': StitchSymbolType.doubleCrochetBackPost,
    'ring_stitch': StitchSymbolType.ringStitch,
    'double_crochet_shell5_in_stitch':
        StitchSymbolType.doubleCrochetShell5InStitch,
    'double_crochet_shell5_over_stitches':
        StitchSymbolType.doubleCrochetShell5OverStitches,
    'attach_yarn': StitchSymbolType.attachYarn,
    'cut_yarn': StitchSymbolType.cutYarn,
  };

  static final Map<StitchSymbolType, String> _typeToId = {
    for (final entry in _idToType.entries) entry.value: entry.key,
  };

  // 未知の id は unknown を返す
  static StitchSymbolType fromId(String id) {
    return _idToType[id] ?? StitchSymbolType.unknown;
  }

  // 公式 Type 向け id（empty / unknown は null）
  static String? idFor(StitchSymbolType type) {
    return _typeToId[type];
  }

  // 公式 Type かどうか（unknown 以外）
  static bool isOfficial(StitchSymbolType type) {
    return type != StitchSymbolType.unknown;
  }

  // PNG アセットを持つ公式 Type かどうか（empty 以外）
  static bool hasOfficialImageAsset(StitchSymbolType type) {
    return type != StitchSymbolType.empty &&
        type != StitchSymbolType.unknown;
  }
}
