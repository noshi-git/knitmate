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

// マスに置ける記号の種類
enum StitchSymbol {
  empty, // 空白
  singleCrochet, // 細編み（×）
  doubleCrochet, // 長編み（T）
  trebleCrochet, // 長々編み（T + 横線2本）
  slipStitch, // 引き抜き編み（●）
}

class PatternEditorPage extends StatefulWidget {
  const PatternEditorPage({super.key});

  // 試作版グリッドのサイズ（10行 × 10列）
  static const int gridRows = 10;
  static const int gridColumns = 10;
  static const double cellSize = 36;

  @override
  State<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends State<PatternEditorPage> {
  // グリッドの各マスの記号（最初はすべて空白）
  late List<List<StitchSymbol>> _grid;

  // 選択中の記号（最初は「細編み」）
  StitchSymbol _selectedSymbol = StitchSymbol.singleCrochet;

  @override
  void initState() {
    super.initState();
    _grid = List.generate(
      PatternEditorPage.gridRows,
      (_) => List.generate(
        PatternEditorPage.gridColumns,
        (_) => StitchSymbol.empty,
      ),
    );
  }

  // マスをタップしたとき、選択中の記号を設定する
  void _onCellTap(int row, int column) {
    setState(() {
      _grid[row][column] = _selectedSymbol;
    });
  }

  // 記号をマス内に表示するウィジェット
  Widget _buildSymbolWidget(BuildContext context, StitchSymbol symbol) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final lineColor = Theme.of(context).colorScheme.onSurface;

    switch (symbol) {
      case StitchSymbol.empty:
        return const SizedBox.shrink();
      case StitchSymbol.singleCrochet:
        return Text('×', style: textStyle);
      case StitchSymbol.doubleCrochet:
        return Text('T', style: textStyle);
      case StitchSymbol.trebleCrochet:
        // T の上に横線を2本（Widget の組み合わせ）
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 1.5, color: lineColor),
            const SizedBox(height: 1),
            Container(width: 12, height: 1.5, color: lineColor),
            const SizedBox(height: 1),
            Text('T', style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      case StitchSymbol.slipStitch:
        return Text('●', style: textStyle);
    }
  }

  // 記号選択ボタン（選択中は FilledButton、未選択は OutlinedButton）
  Widget _buildSymbolButton(StitchSymbol symbol, String label) {
    final isSelected = _selectedSymbol == symbol;

    if (isSelected) {
      return FilledButton(
        onPressed: () {
          setState(() {
            _selectedSymbol = symbol;
          });
        },
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedSymbol = symbol;
        });
      },
      child: Text(label),
    );
  }

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
        child: Column(
          children: [
            // 10×10 グリッド（はみ出す場合は縦横にスクロール）
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(PatternEditorPage.gridRows, (row) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                List.generate(PatternEditorPage.gridColumns, (column) {
                              return GestureDetector(
                                onTap: () => _onCellTap(row, column),
                                child: Container(
                                  width: PatternEditorPage.cellSize,
                                  height: PatternEditorPage.cellSize,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                  ),
                                  alignment: Alignment.center,
                                  child: _buildSymbolWidget(
                                    context,
                                    _grid[row][column],
                                  ),
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
            // 画面下部：5種類の記号を選ぶボタン（横スクロール対応）
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSymbolButton(StitchSymbol.empty, '空白'),
                    const SizedBox(width: 8),
                    _buildSymbolButton(StitchSymbol.singleCrochet, '細編み'),
                    const SizedBox(width: 8),
                    _buildSymbolButton(StitchSymbol.doubleCrochet, '長編み'),
                    const SizedBox(width: 8),
                    _buildSymbolButton(StitchSymbol.trebleCrochet, '長々編み'),
                    const SizedBox(width: 8),
                    _buildSymbolButton(StitchSymbol.slipStitch, '引き抜き編み'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
