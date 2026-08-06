import 'package:flutter/material.dart';

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

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // 現在の目数（初期値は 0）
  int _count = 0;

  // ＋ボタン：1 増やす
  void _increment() {
    setState(() {
      _count++;
    });
  }

  // －ボタン：1 減らす（0 未満にはならない）
  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
      });
    }
  }

  // リセットボタン：0 に戻す
  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  // 目数カウンター画面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // タイトルバー（← 戻るボタンは自動で表示される）
      appBar: AppBar(
        title: const Text('目数カウンター'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 中央に現在の目数を大きく表示
              Expanded(
                child: Center(
                  child: Text(
                    '$_count',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
              // ＋・－・リセットボタンを縦に並べる
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _increment,
                  child: const Text('＋'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _decrement,
                  child: const Text('－'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('リセット'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatternEditorPage extends StatelessWidget {
  const PatternEditorPage({super.key});

  // 試作版グリッドのサイズ（10行 × 10列）
  static const int gridRows = 10;
  static const int gridColumns = 10;
  static const double cellSize = 36;

  // 編み図エディタ画面
  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outline;

    return Scaffold(
      // タイトルバー（← 戻るボタンは自動で表示される）
      appBar: AppBar(
        title: const Text('編み図エディタ'),
      ),
      body: SafeArea(
        child: Center(
          // はみ出す場合は縦横にスクロールできる
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(gridRows, (row) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(gridColumns, (column) {
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
