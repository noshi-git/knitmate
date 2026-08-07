// 編み図作品のデータ
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.grid,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int rows;
  final int columns;
  final List<List<int>> grid;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 作品ごとに重複しないIDを生成する
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rows': rows,
      'columns': columns,
      'grid': grid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      grid: (json['grid'] as List<dynamic>)
          .map(
            (row) => (row as List<dynamic>).map((value) => value as int).toList(),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // 保存時に内容だけ更新する
  Project copyWith({
    String? name,
    int? rows,
    int? columns,
    List<List<int>>? grid,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      grid: grid ?? this.grid,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
