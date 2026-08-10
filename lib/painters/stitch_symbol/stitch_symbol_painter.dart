import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/stitch_symbol_type.dart';
import 'catalog/step1_basic_symbols.dart';
import 'catalog/step2_t_family_symbols.dart';
import 'catalog/step3_inc_dec_symbols.dart';
import 'catalog/step4_special_symbols.dart';
import 'catalog/step5_other_symbols.dart';
import 'stitch_symbol_display_scale.dart';
import 'stitch_symbol_geometry.dart';
import 'stitch_symbol_image_cache.dart';
import 'stitch_symbol_metrics.dart';
import 'stitch_symbol_style.dart';

// 公式編み記号を描画する（公式36種は PNG、ロールバック用 Vector コードは残置）
class StitchSymbolPainter {
  const StitchSymbolPainter();

  static const _useOfficialImageAssets = true;

  /// 公式 Type を PNG 描画する。
  /// [StitchSymbolType.unknown] / [StitchSymbolType.empty] の場合は描画せず false。
  bool paint({
    required Canvas canvas,
    required Rect cellRect,
    required StitchSymbolType type,
    required Color color,
    double displayScale = StitchSymbolDisplayScale.preview,
  }) {
    if (type == StitchSymbolType.empty || type == StitchSymbolType.unknown) {
      return false;
    }

    if (_useOfficialImageAssets &&
        StitchSymbolTypeMapper.hasOfficialImageAsset(type)) {
      unawaited(StitchSymbolImageCache.ensureLoaded(type));
      return StitchSymbolImageCache.paint(
        canvas: canvas,
        cellRect: cellRect,
        type: type,
        color: color,
        displayScale: displayScale,
      );
    }

    final metrics = StitchSymbolMetrics.forCell(cellRect.shortestSide);
    final style = StitchSymbolStyle(color: color);
    final geometry = StitchSymbolGeometry(metrics: metrics, style: style);
    final contentRect = _contentRect(cellRect, metrics);

    switch (type) {
      case StitchSymbolType.chain:
        Step1BasicSymbols.paintChain(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.slipStitch:
        Step1BasicSymbols.paintSlipStitch(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.singleCrochet:
        Step1BasicSymbols.paintSingleCrochet(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.halfDoubleCrochet:
        Step2TFamilySymbols.paintHalfDoubleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochet:
        Step2TFamilySymbols.paintDoubleCrochet(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.trebleCrochet:
        Step2TFamilySymbols.paintTrebleCrochet(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.singleCrochetInc2:
        Step3IncDecSymbols.paintSingleCrochetInc2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetInc3:
        Step3IncDecSymbols.paintSingleCrochetInc3(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetDec2:
        Step3IncDecSymbols.paintSingleCrochetDec2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.halfDoubleCrochetInc2:
        Step3IncDecSymbols.paintHalfDoubleCrochetInc2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.halfDoubleCrochetDec2:
        Step3IncDecSymbols.paintHalfDoubleCrochetDec2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetInc2:
        Step3IncDecSymbols.paintDoubleCrochetInc2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetDec2:
        Step3IncDecSymbols.paintDoubleCrochetDec2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.trebleCrochetInc2:
        Step3IncDecSymbols.paintTrebleCrochetInc2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.trebleCrochetDec2:
        Step3IncDecSymbols.paintTrebleCrochetDec2(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetFrontPost:
        Step4SpecialSymbols.paintSingleCrochetFrontPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetBackPost:
        Step4SpecialSymbols.paintSingleCrochetBackPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetCh1SingleCrochet:
        Step4SpecialSymbols.paintSingleCrochetCh1SingleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.singleCrochetCh2SingleCrochet:
        Step4SpecialSymbols.paintSingleCrochetCh2SingleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.ribSingleCrochet:
        Step4SpecialSymbols.paintRibSingleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.reverseSingleCrochet:
        Step4SpecialSymbols.paintReverseSingleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.twistedSingleCrochet:
        Step4SpecialSymbols.paintTwistedSingleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.picot:
        Step4SpecialSymbols.paintPicot(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.halfDoubleCrochetCluster3:
        Step4SpecialSymbols.paintHalfDoubleCrochetCluster3(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.halfDoubleCrochetFrontPost:
        Step4SpecialSymbols.paintHalfDoubleCrochetFrontPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.halfDoubleCrochetBackPost:
        Step4SpecialSymbols.paintHalfDoubleCrochetBackPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.crossedDoubleCrochet:
        Step4SpecialSymbols.paintCrossedDoubleCrochet(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetCluster3:
        Step4SpecialSymbols.paintDoubleCrochetCluster3(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetPopcorn5:
        Step4SpecialSymbols.paintDoubleCrochetPopcorn5(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetFrontPost:
        Step5OtherSymbols.paintDoubleCrochetFrontPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetBackPost:
        Step5OtherSymbols.paintDoubleCrochetBackPost(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.ringStitch:
        Step5OtherSymbols.paintRingStitch(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.doubleCrochetShell5InStitch:
        Step5OtherSymbols.paintDoubleCrochetShell5InStitch(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.doubleCrochetShell5OverStitches:
        Step5OtherSymbols.paintDoubleCrochetShell5OverStitches(
          canvas,
          contentRect,
          geometry,
        );
        return true;
      case StitchSymbolType.attachYarn:
        Step5OtherSymbols.paintAttachYarn(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.cutYarn:
        Step5OtherSymbols.paintCutYarn(canvas, contentRect, geometry);
        return true;
      case StitchSymbolType.empty:
      case StitchSymbolType.unknown:
        return false;
    }
  }

  Rect _contentRect(Rect cellRect, StitchSymbolMetrics metrics) {
    final pad = cellRect.shortestSide * metrics.padding;
    return Rect.fromLTRB(
      cellRect.left + pad,
      cellRect.top + pad,
      cellRect.right - pad,
      cellRect.bottom - pad,
    );
  }
}
