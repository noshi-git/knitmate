// 1回の編集操作で変更されたセルの差分（Undo用）
class CellChange {
  const CellChange({
    required this.row,
    required this.column,
    required this.previousStorageIndex,
  });

  final int row;
  final int column;
  final int previousStorageIndex;
}
