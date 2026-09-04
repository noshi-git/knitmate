import 'package:flutter/services.dart';

import '../models/stitch_definition.dart';

/// 編み記号ショートカットキーの正規化・検証。
class StitchShortcutKey {
  StitchShortcutKey._();

  static const List<String> allowedFunctionKeys = [
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
  ];

  static final Set<LogicalKeyboardKey> _forbiddenLogicalKeys = {
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.backspace,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  /// 保存用文字列へ正規化する。未対応の場合は null。
  static String? normalize(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final upper = trimmed.toUpperCase();
    if (RegExp(r'^[A-Z0-9]$').hasMatch(upper)) {
      return upper;
    }
    if (allowedFunctionKeys.contains(upper)) {
      return upper;
    }
    return null;
  }

  /// KeyDownEvent から正規化キーを取得する。
  static String? fromKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return null;
    }
    if (hasModifierPressed(event)) {
      return null;
    }
    return fromLogicalKey(event.logicalKey);
  }

  static String? fromLogicalKey(LogicalKeyboardKey key) {
    if (_forbiddenLogicalKeys.contains(key)) {
      return null;
    }

    for (var i = 0; i < 10; i++) {
      if (key == _digitKeys[i] || key == _numpadKeys[i]) {
        return '$i';
      }
    }

    for (final functionKey in allowedFunctionKeys) {
      if (key == _functionKeys[functionKey]) {
        return functionKey;
      }
    }

    final label = key.keyLabel;
    if (label.length == 1) {
      final upper = label.toUpperCase();
      if (RegExp(r'^[A-Z]$').hasMatch(upper)) {
        return upper;
      }
    }

    return null;
  }

  static bool hasModifierPressed(KeyEvent event) {
    return HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed;
  }

  static bool isAllowed(String? normalized) {
    return normalized != null;
  }

  /// 他の定義で同じキーが使われている場合、その定義を返す。
  static StitchDefinition? findDuplicateOwner({
    required List<StitchDefinition> definitions,
    required String? shortcutKey,
    required String excludeDefinitionId,
  }) {
    final normalized = normalize(shortcutKey);
    if (normalized == null) {
      return null;
    }

    for (final definition in definitions) {
      if (definition.id == excludeDefinitionId) {
        continue;
      }
      if (normalize(definition.shortcutKey) == normalized) {
        return definition;
      }
    }
    return null;
  }

  /// キーイベントに一致する有効な編み記号を返す。
  static StitchDefinition? findDefinitionForKeyEvent({
    required List<StitchDefinition> definitions,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent) {
      return null;
    }
    if (hasModifierPressed(event)) {
      return null;
    }
    final key = fromKeyEvent(event);
    if (key == null) {
      return null;
    }
    return findDefinitionForShortcutKey(
      definitions: definitions,
      shortcutKey: key,
    );
  }

  /// 正規化済みキーに一致する有効な編み記号を返す。
  static StitchDefinition? findDefinitionForShortcutKey({
    required List<StitchDefinition> definitions,
    required String shortcutKey,
  }) {
    final normalized = normalize(shortcutKey);
    if (normalized == null) {
      return null;
    }

    for (final definition in definitions) {
      if (!definition.enabled || definition.system) {
        continue;
      }
      if (normalize(definition.shortcutKey) == normalized) {
        return definition;
      }
    }
    return null;
  }

  static const List<LogicalKeyboardKey> _digitKeys = [
    LogicalKeyboardKey.digit0,
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  static const List<LogicalKeyboardKey> _numpadKeys = [
    LogicalKeyboardKey.numpad0,
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
    LogicalKeyboardKey.numpad4,
    LogicalKeyboardKey.numpad5,
    LogicalKeyboardKey.numpad6,
    LogicalKeyboardKey.numpad7,
    LogicalKeyboardKey.numpad8,
    LogicalKeyboardKey.numpad9,
  ];

  static const Map<String, LogicalKeyboardKey> _functionKeys = {
    'F1': LogicalKeyboardKey.f1,
    'F2': LogicalKeyboardKey.f2,
    'F3': LogicalKeyboardKey.f3,
    'F4': LogicalKeyboardKey.f4,
    'F5': LogicalKeyboardKey.f5,
    'F6': LogicalKeyboardKey.f6,
    'F7': LogicalKeyboardKey.f7,
    'F8': LogicalKeyboardKey.f8,
    'F9': LogicalKeyboardKey.f9,
    'F10': LogicalKeyboardKey.f10,
    'F11': LogicalKeyboardKey.f11,
    'F12': LogicalKeyboardKey.f12,
  };
}
