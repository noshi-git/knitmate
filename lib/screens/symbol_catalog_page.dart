import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../services/stitch_settings_service.dart';
import '../widgets/stitch_symbol_preview.dart';

/// 開発専用: 公式36記号を同一セル条件で一覧比較する画面
class SymbolCatalogPage extends StatelessWidget {
  const SymbolCatalogPage({super.key});

  static const double _cardWidth = 140;
  static const double _cardHeight = 176;
  static const double _symbolExtent = 72;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final definitions = StitchSettingsService().officialCatalogDefinitions();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbol Catalog（開発用）'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final definition in definitions)
                  _CatalogCard(
                    definition: definition,
                    width: _cardWidth,
                    height: _cardHeight,
                    symbolExtent: _symbolExtent,
                    color: onSurface,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.definition,
    required this.width,
    required this.height,
    required this.symbolExtent,
    required this.color,
  });

  final StitchDefinition definition;
  final double width;
  final double height;
  final double symbolExtent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              child: Column(
                children: [
                  StitchSymbolPreview(
                    definition: definition,
                    size: Size(symbolExtent, symbolExtent),
                    color: color,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        definition.name,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    definition.id,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 6,
              child: Text(
                '${definition.storageIndex}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
