/// Split / format stitch names for settings + editor selector labels.
class StitchDisplayName {
  StitchDisplayName._();

  /// mainName + optional annotation starting with "（" or "(".
  static ({String mainName, String? annotation}) split(String name) {
    final fullWidth = name.indexOf('（');
    final halfWidth = name.indexOf('(');
    final index = _earlierIndex(fullWidth, halfWidth);
    if (index <= 0) {
      return (mainName: name, annotation: null);
    }

    final head = name.substring(0, index).trimRight();
    final tail = name.substring(index);
    if (head.isEmpty) {
      return (mainName: name, annotation: null);
    }
    return (mainName: head, annotation: tail);
  }

  /// Legacy helper: mainName and annotation joined by a newline.
  static String format(String name) {
    final parts = split(name);
    final annotation = parts.annotation;
    if (annotation == null) {
      return parts.mainName;
    }
    return '${parts.mainName}\n$annotation';
  }

  static int _earlierIndex(int a, int b) {
    if (a < 0) {
      return b;
    }
    if (b < 0) {
      return a;
    }
    return a < b ? a : b;
  }
}
