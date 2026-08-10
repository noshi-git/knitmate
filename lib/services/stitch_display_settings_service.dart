import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stitch_label_display_mode.dart';
import '../models/symbol_display_scale.dart';

// 編み記号ラベルの表示方法と PNG シンボル倍率を共通管理する
class StitchDisplaySettingsService extends ChangeNotifier {
  StitchDisplaySettingsService._();

  static final StitchDisplaySettingsService instance =
      StitchDisplaySettingsService._();

  static const String _displayModeKey = 'stitch_label_display_mode';
  static const String _cellSymbolScaleKey = 'symbol_display_scale_cell';
  static const String _buttonSymbolScaleKey = 'symbol_display_scale_button';

  StitchLabelDisplayMode _displayMode = StitchLabelDisplayMode.symbolAndName;
  SymbolDisplayScale _cellSymbolScale = SymbolDisplayScale.defaultCell;
  SymbolDisplayScale _buttonSymbolScale = SymbolDisplayScale.defaultButton;
  bool _loaded = false;

  StitchLabelDisplayMode get displayMode => _displayMode;

  SymbolDisplayScale get cellSymbolScale => _cellSymbolScale;

  double get cellSymbolScaleValue => _cellSymbolScale.value;

  SymbolDisplayScale get buttonSymbolScale => _buttonSymbolScale;

  double get buttonSymbolScaleValue => _buttonSymbolScale.value;

  bool get isLoaded => _loaded;

  // SharedPreferences から読み込む
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_displayModeKey);
    _displayMode = StitchLabelDisplayModeX.fromStorage(storedMode);
    _cellSymbolScale = SymbolDisplayScaleX.fromStorage(
      prefs.getString(_cellSymbolScaleKey),
      fallback: SymbolDisplayScale.defaultCell,
    );
    _buttonSymbolScale = SymbolDisplayScaleX.fromStorage(
      prefs.getString(_buttonSymbolScaleKey),
      fallback: SymbolDisplayScale.defaultButton,
    );
    _loaded = true;
    notifyListeners();
  }

  // 表示方法を保存して通知する
  Future<void> setDisplayMode(StitchLabelDisplayMode mode) async {
    if (_displayMode == mode && _loaded) {
      return;
    }

    _displayMode = mode;
    _loaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayModeKey, mode.storageValue);
  }

  Future<void> setCellSymbolScale(SymbolDisplayScale scale) async {
    if (_cellSymbolScale == scale && _loaded) {
      return;
    }

    _cellSymbolScale = scale;
    _loaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cellSymbolScaleKey, scale.storageValue);
  }

  Future<void> setButtonSymbolScale(SymbolDisplayScale scale) async {
    if (_buttonSymbolScale == scale && _loaded) {
      return;
    }

    _buttonSymbolScale = scale;
    _loaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_buttonSymbolScaleKey, scale.storageValue);
  }
}
