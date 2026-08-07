import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

// 作品をJSONファイルで保存・読み込みする
class ProjectStorageService {
  static const String _projectsFolderName = 'KnitMate/projects';

  // 作品保存フォルダを取得する（なければ作成）
  Future<Directory> _getProjectsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDir.path}/$_projectsFolderName');

    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }

    return projectsDir;
  }

  // 作品をJSONファイルとして保存する
  Future<void> saveProject(Project project) async {
    final projectsDir = await _getProjectsDirectory();
    final file = File('${projectsDir.path}/${project.id}.json');
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  // 保存されている作品をすべて読み込む（更新日時の新しい順）
  Future<List<Project>> loadProjects() async {
    final projectsDir = await _getProjectsDirectory();
    if (!await projectsDir.exists()) {
      return [];
    }

    final projects = <Project>[];

    await for (final entity in projectsDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      try {
        final jsonText = await entity.readAsString();
        final decoded = jsonDecode(jsonText);
        if (decoded is Map<String, dynamic>) {
          projects.add(Project.fromJson(decoded));
        }
      } catch (_) {
        // 不正なJSONファイルはスキップして、他の作品は読み込む
      }
    }

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  // 指定IDの作品を1件読み込む
  Future<Project?> loadProject(String id) async {
    final projectsDir = await _getProjectsDirectory();
    final file = File('${projectsDir.path}/$id.json');

    if (!await file.exists()) {
      return null;
    }

    try {
      final jsonText = await file.readAsString();
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return Project.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
