import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/symbol_display_scale.dart';
import '../services/stitch_display_settings_service.dart';
import 'stitch_settings_page.dart';
import 'symbol_catalog_page.dart';

// アプリの設定画面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListenableBuilder(
        listenable: StitchDisplaySettingsService.instance,
        builder: (context, _) {
          final displaySettings = StitchDisplaySettingsService.instance;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'シンボル表示サイズ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'セル内シンボルサイズ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _SymbolScaleSelector(
                        selected: displaySettings.cellSymbolScale,
                        onSelected: displaySettings.setCellSymbolScale,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ボタン内シンボルサイズ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _SymbolScaleSelector(
                        selected: displaySettings.buttonSymbolScale,
                        onSelected: displaySettings.setButtonSymbolScale,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              Card(
                child: ListTile(
                  title: const Text('Symbol Catalog'),
                  subtitle: const Text('開発用・公式36記号の比較一覧'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SymbolCatalogPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: _AppAboutTile(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppAboutTile extends StatelessWidget {
  const _AppAboutTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('アプリについて'),
      subtitle: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('KnitMate');
          }
          if (!snapshot.hasData) {
            return const Text('KnitMate');
          }
          return Text('KnitMate Version ${snapshot.data!.version}');
        },
      ),
    );
  }
}

class _SymbolScaleSelector extends StatelessWidget {
  const _SymbolScaleSelector({
    required this.selected,
    required this.onSelected,
  });

  final SymbolDisplayScale selected;
  final ValueChanged<SymbolDisplayScale> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SymbolDisplayScale>(
      segments: [
        for (final scale in SymbolDisplayScale.values)
          ButtonSegment<SymbolDisplayScale>(
            value: scale,
            label: Text(scale.label),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) {
        onSelected(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}
