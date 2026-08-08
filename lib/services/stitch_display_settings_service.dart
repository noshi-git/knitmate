import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stitch_label_display_mode.dart';

// 編み記号ラベルの表示方法を共通管理する
class StitchDisplaySettingsService extends ChangeNotifier {
  StitchDisplaySettingsService._();

  static final StitchDisplaySettingsService instance =
      StitchDisplaySettingsService._();

  static const String _displayModeKey = 'stitch_label_display_mode';

  StitchLabelDisplayMode _displayMode = StitchLabelDisplayMode.symbolAndName;
  bool _loaded = false;

  StitchLabelDisplayMode get displayMode => _displayMode;

  bool get isLoaded => _loaded;

  // SharedPreferences から読み込む
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_displayModeKey);
    _displayMode = StitchLabelDisplayModeX.fromStorage(stored);
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
}
