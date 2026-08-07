import '../models/stitch_symbol.dart';

// 1回の編集操作で変更されたセルの差分（Undo用）
class CellChange {
  const CellChange({
    required this.row,
    required this.column,
    required this.previousSymbol,
  });

  final int row;
  final int column;
  final StitchSymbol previousSymbol;
}
