import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knitmate/models/stitch_definition.dart';
import 'package:knitmate/models/stitch_label_display_mode.dart';
import 'package:knitmate/services/stitch_display_settings_service.dart';
import 'package:knitmate/widgets/stitch_selector_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StitchDisplaySettingsService.instance.load();
  });

  const plainDefinition = StitchDefinition(
    id: 'single_crochet',
    name: '細編み',
    symbol: '',
    enabled: true,
    system: false,
    storageIndex: 1,
  );

  const coloredDefinition = StitchDefinition(
    id: 'double_crochet',
    name: '長編み',
    symbol: '',
    enabled: true,
    system: false,
    storageIndex: 2,
    cellBackgroundColor: 0xFFFFFF00,
  );

  Future<void> pumpButton(
    WidgetTester tester, {
    required StitchDefinition definition,
    required bool selected,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: StitchSelectorButton(
              definition: definition,
              selected: selected,
              displayMode: StitchLabelDisplayMode.symbolAndName,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('色なしDefinitionは従来のMaterialボタンを使う', (tester) async {
    await pumpButton(
      tester,
      definition: plainDefinition,
      selected: false,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('色なしDefinitionの選択中はFilledButtonを使う', (tester) async {
    await pumpButton(
      tester,
      definition: plainDefinition,
      selected: true,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('色ありDefinitionは設定色リングとsurface中央背景を使う', (tester) async {
    final theme = ThemeData(useMaterial3: true);
    await pumpButton(
      tester,
      definition: coloredDefinition,
      selected: false,
      theme: theme,
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final backgroundColor = button.style?.backgroundColor?.resolve({});
    expect(backgroundColor, Colors.transparent);

    final customPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('stitch_selector_color_ring')),
    );
    final painter =
        customPaint.painter! as StitchSelectorColorBandPainter;
    expect(painter.surfaceColor, theme.colorScheme.surface);
    expect(painter.ringColor, const Color(0xFFFFFF00));
    expect(painter.ringWidth, StitchSelectorButton.ringWidth);
  });

  testWidgets('色ありDefinitionの選択中はチェックアイコンを表示する', (tester) async {
    await pumpButton(
      tester,
      definition: coloredDefinition,
      selected: true,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('色ありDefinitionはライト/ダークテーマで描画できる', (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await pumpButton(
        tester,
        definition: coloredDefinition,
        selected: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: brightness,
          ),
        ),
      );

      expect(find.byType(StitchSelectorButton), findsOneWidget);
      expect(find.text('長編み'), findsOneWidget);
    }
  });

  Future<void> pumpButtonPair(
    WidgetTester tester, {
    required StitchDefinition plain,
    required StitchDefinition colored,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: const Key('plain_button'),
                child: StitchSelectorButton(
                  definition: plain,
                  selected: false,
                  displayMode: StitchLabelDisplayMode.symbolAndName,
                  onPressed: () {},
                ),
              ),
              KeyedSubtree(
                key: const Key('colored_button'),
                child: StitchSelectorButton(
                  definition: colored,
                  selected: false,
                  displayMode: StitchLabelDisplayMode.symbolAndName,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('同一Definitionで色の有無によりボタンサイズが同じ', (tester) async {
    const plain = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
    );
    const colored = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
      cellBackgroundColor: 0xFF0000FF,
    );

    await pumpButtonPair(tester, plain: plain, colored: colored);

    final plainSize = tester.getSize(find.byKey(const Key('plain_button')));
    final coloredSize = tester.getSize(find.byKey(const Key('colored_button')));

    expect(plainSize.width, coloredSize.width);
    expect(plainSize.height, coloredSize.height);
  });

  testWidgets('長い名称でも色の有無でボタンサイズが同じ', (tester) async {
    const plain = StitchDefinition(
      id: 'double_crochet_shell5_over_stitches',
      name: '長編み５目のシェル（複数目上）',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 34,
    );
    const colored = StitchDefinition(
      id: 'double_crochet_shell5_over_stitches',
      name: '長編み５目のシェル（複数目上）',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 34,
      cellBackgroundColor: 0xFF00BFFF,
    );

    await pumpButtonPair(tester, plain: plain, colored: colored);

    final plainSize = tester.getSize(find.byKey(const Key('plain_button')));
    final coloredSize = tester.getSize(find.byKey(const Key('colored_button')));

    expect(plainSize.width, coloredSize.width);
    expect(plainSize.height, coloredSize.height);
  });

  testWidgets('色ありDefinitionの選択中でも未選択とボタンサイズが同じ', (tester) async {
    const colored = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
      cellBackgroundColor: 0xFF0000FF,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: const Key('unselected_button'),
                child: StitchSelectorButton(
                  definition: colored,
                  selected: false,
                  displayMode: StitchLabelDisplayMode.symbolAndName,
                  onPressed: () {},
                ),
              ),
              KeyedSubtree(
                key: const Key('selected_button'),
                child: StitchSelectorButton(
                  definition: colored,
                  selected: true,
                  displayMode: StitchLabelDisplayMode.symbolAndName,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final unselectedSize =
        tester.getSize(find.byKey(const Key('unselected_button')));
    final selectedSize =
        tester.getSize(find.byKey(const Key('selected_button')));

    expect(unselectedSize.width, selectedSize.width);
    expect(unselectedSize.height, selectedSize.height);
  });

  Future<Size> pumpSingleButtonSize(
    WidgetTester tester, {
    required StitchDefinition definition,
    required bool selected,
    required StitchLabelDisplayMode displayMode,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: KeyedSubtree(
              key: const Key('target_button'),
              child: StitchSelectorButton(
                definition: definition,
                selected: selected,
                displayMode: displayMode,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getSize(find.byKey(const Key('target_button')));
  }

  testWidgets('短い名称のボタンは縦横ほぼ同寸の円形', (tester) async {
    const definition = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
    );

    final size = await pumpSingleButtonSize(
      tester,
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    final button = StitchSelectorButton(
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
      onPressed: () {},
    );
    expect(button.usesCircularShape, isTrue);
    expect(size.width / size.height, closeTo(1.0, 0.12));

    final outlined = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(outlined.style?.shape?.resolve({}), isA<CircleBorder>());
  });

  testWidgets('長い名称のボタンは横長スタジアム形', (tester) async {
    const definition = StitchDefinition(
      id: 'half_double_crochet_dec2',
      name: '中長編み2目一度',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 11,
    );

    final button = StitchSelectorButton(
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
      onPressed: () {},
    );
    expect(button.usesCircularShape, isFalse);

    final size = await pumpSingleButtonSize(
      tester,
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    expect(size.width, greaterThan(size.height * 1.05));

    final outlined = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(outlined.style?.shape?.resolve({}), isA<StadiumBorder>());
  });

  testWidgets('色あり/色なしで同一shapeとサイズ', (tester) async {
    const plain = StitchDefinition(
      id: 'treble_crochet',
      name: '長々編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 3,
    );
    const colored = StitchDefinition(
      id: 'treble_crochet',
      name: '長々編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 3,
      cellBackgroundColor: 0xFFFFFF00,
    );

    await pumpButtonPair(tester, plain: plain, colored: colored);

    final plainSize = tester.getSize(find.byKey(const Key('plain_button')));
    final coloredSize = tester.getSize(find.byKey(const Key('colored_button')));

    expect(plainSize, coloredSize);

    final plainShape = tester
        .widget<OutlinedButton>(
          find.descendant(
            of: find.byKey(const Key('plain_button')),
            matching: find.byType(OutlinedButton),
          ),
        )
        .style
        ?.shape
        ?.resolve({});
    final coloredShape = tester
        .widget<OutlinedButton>(
          find.descendant(
            of: find.byKey(const Key('colored_button')),
            matching: find.byType(OutlinedButton),
          ),
        )
        .style
        ?.shape
        ?.resolve({});

    expect(plainShape.runtimeType, coloredShape.runtimeType);
    expect(plainShape, isA<CircleBorder>());

    final painter = tester.widget<CustomPaint>(
      find.byKey(const Key('stitch_selector_color_ring')),
    ).painter! as StitchSelectorColorBandPainter;
    expect(painter.isCircular, isTrue);
  });

  testWidgets('選択中でもshapeとサイズを維持する', (tester) async {
    const colored = StitchDefinition(
      id: 'double_crochet',
      name: '長編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 2,
      cellBackgroundColor: 0xFF0000FF,
    );

    final unselectedSize = await pumpSingleButtonSize(
      tester,
      definition: colored,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    final selectedSize = await pumpSingleButtonSize(
      tester,
      definition: colored,
      selected: true,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    expect(unselectedSize, selectedSize);

    final shape = tester
        .widget<OutlinedButton>(find.byType(OutlinedButton))
        .style
        ?.shape
        ?.resolve({});
    expect(shape, isA<CircleBorder>());
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  Future<Size> pumpLongNameInWideWrap(WidgetTester tester) async {
    const definition = StitchDefinition(
      id: 'double_crochet_shell5_in_stitch',
      name: '長編み5目を前段の1目に編み入れる',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 33,
    );

    const parentWidth = 800.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: parentWidth,
            child: Wrap(
              children: [
                KeyedSubtree(
                  key: const Key('long_button'),
                  child: StitchSelectorButton(
                    definition: definition,
                    selected: false,
                    displayMode: StitchLabelDisplayMode.symbolAndName,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    return tester.getSize(find.byKey(const Key('long_button')));
  }

  testWidgets('長い名称ボタンは親幅いっぱいに伸びない', (tester) async {
    const parentWidth = 800.0;
    final size = await pumpLongNameInWideWrap(tester);

    expect(size.width, lessThan(parentWidth * 0.75));
  });

  testWidgets('長い名称ボタンのwidthはmaxWidth以下', (tester) async {
    final size = await pumpLongNameInWideWrap(tester);

    expect(
      size.width,
      lessThanOrEqualTo(StitchSelectorButton.longNameMaxWidth + 48),
    );
  });

  testWidgets('短い名称ボタンは従来サイズを維持する', (tester) async {
    const definition = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
    );

    final size = await pumpSingleButtonSize(
      tester,
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    expect(size.width, lessThan(120));
    expect(size.height, lessThan(120));
    expect(size.width / size.height, closeTo(1.0, 0.12));
  });

  testWidgets('長い名称でも色あり/色なしでサイズ一致', (tester) async {
    const plain = StitchDefinition(
      id: 'double_crochet_shell5_in_stitch',
      name: '長編み5目を前段の1目に編み入れる',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 33,
    );
    const colored = StitchDefinition(
      id: 'double_crochet_shell5_in_stitch',
      name: '長編み5目を前段の1目に編み入れる',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 33,
      cellBackgroundColor: 0xFF00BFFF,
    );

    await pumpButtonPair(tester, plain: plain, colored: colored);

    final plainSize = tester.getSize(find.byKey(const Key('plain_button')));
    final coloredSize = tester.getSize(find.byKey(const Key('colored_button')));

    expect(plainSize, coloredSize);
  });

  testWidgets('長い名称でも選択中はサイズを維持する', (tester) async {
    const definition = StitchDefinition(
      id: 'double_crochet_shell5_in_stitch',
      name: '長編み5目を前段の1目に編み入れる',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 33,
      cellBackgroundColor: 0xFF00BFFF,
    );

    final unselectedSize = await pumpSingleButtonSize(
      tester,
      definition: definition,
      selected: false,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    final selectedSize = await pumpSingleButtonSize(
      tester,
      definition: definition,
      selected: true,
      displayMode: StitchLabelDisplayMode.symbolAndName,
    );

    expect(unselectedSize, selectedSize);
  });

  testWidgets('shortcutKeyなしボタンはキーバッジを表示しない', (tester) async {
    await pumpButton(
      tester,
      definition: plainDefinition,
      selected: false,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byKey(const Key('stitch_selector_shortcut_badge')), findsNothing);
  });

  testWidgets('shortcutKeyありボタンはキーバッジを表示する', (tester) async {
    const definition = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
      shortcutKey: '1',
    );

    await pumpButton(
      tester,
      definition: definition,
      selected: false,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byKey(const Key('stitch_selector_shortcut_badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('色あり + shortcutKey で色リングとキーバッジが共存する', (tester) async {
    const definition = StitchDefinition(
      id: 'double_crochet',
      name: '長編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 2,
      cellBackgroundColor: 0xFFFFFF00,
      shortcutKey: '2',
    );

    await pumpButton(
      tester,
      definition: definition,
      selected: false,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byKey(const Key('stitch_selector_color_ring')), findsOneWidget);
    expect(find.byKey(const Key('stitch_selector_shortcut_badge')), findsOneWidget);
  });

  testWidgets('選択中 + shortcutKey でチェックとキーバッジが共存する', (tester) async {
    const definition = StitchDefinition(
      id: 'double_crochet',
      name: '長編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 2,
      cellBackgroundColor: 0xFFFFFF00,
      shortcutKey: 'A',
    );

    await pumpButton(
      tester,
      definition: definition,
      selected: true,
      theme: ThemeData(useMaterial3: true),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byKey(const Key('stitch_selector_shortcut_badge')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('shortcutKey追加前後でボタンサイズが変わらない', (tester) async {
    const withoutShortcut = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
    );
    const withShortcut = StitchDefinition(
      id: 'single_crochet',
      name: '細編み',
      symbol: '',
      enabled: true,
      system: false,
      storageIndex: 1,
      shortcutKey: '1',
    );

    await pumpButtonPair(
      tester,
      plain: withoutShortcut,
      colored: withShortcut,
    );

    final withoutSize = tester.getSize(find.byKey(const Key('plain_button')));
    final withSize = tester.getSize(find.byKey(const Key('colored_button')));

    expect(withoutSize.width, withSize.width);
    expect(withoutSize.height, withSize.height);
  });
}
