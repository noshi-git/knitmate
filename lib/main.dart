import 'package:flutter/material.dart';

import 'screens/counter_page.dart';
import 'screens/pattern_editor_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // アプリ全体のルート（土台）ウィジェット
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KnitMate',
      // Material Design 3 を使う設定
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  // KnitMate のホーム画面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 画面上部のタイトルバー
      appBar: AppBar(
        title: const Text('KnitMate'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 中央のウェルカムメッセージ
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ようこそ KnitMateへ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '編み物をもっと楽しく。',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              // 「編み始める」ボタン → 目数カウンター画面へ移動
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CounterPage(),
                      ),
                    );
                  },
                  child: const Text('編み始める'),
                ),
              ),
              const SizedBox(height: 12),
              // 「編み図」ボタン → 編み図エディタ画面へ移動
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatternEditorPage(),
                      ),
                    );
                  },
                  child: const Text('編み図'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

