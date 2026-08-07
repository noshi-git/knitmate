import 'package:flutter/material.dart';

import 'stitch_settings_page.dart';

// アプリの設定画面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 編み記号の設定（Step2で中身を実装予定）
          Card(
            child: ListTile(
              title: const Text('編み記号'),
              subtitle: const Text('名称や表示記号を変更できます'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StitchSettingsPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // アプリ情報（表示のみ）
          const Card(
            child: ListTile(
              title: Text('アプリについて'),
              subtitle: Text('KnitMate Version 3.0'),
            ),
          ),
        ],
      ),
    );
  }
}
