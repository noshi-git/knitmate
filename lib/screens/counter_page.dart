import 'package:flutter/material.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // 現在の目数
  int _count = 0;

  // 目数を1増やす
  void _increment() {
    setState(() {
      _count++;
    });
  }

  // 目数を1減らす。0未満にはしない
  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
      });
    }
  }

  // 目数を0へ戻す
  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目数カウンター'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '$_count',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
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