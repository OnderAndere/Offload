import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/items/item_type_look.dart';
import 'package:offload/presentation/theme/app_theme.dart';

/// The type of an item on its card: icon and name, never colour alone
/// (T2.10, DD-018 point 2, REQ-016).
void main() {
  final id = UuidV7Generator().next();

  Item item(ItemType? type) => Item(
    id: id,
    rawText: 'Logboek bijhouden #renovatie',
    status: ItemStatus.active,
    source: ItemSource.app,
    type: type,
  );

  Future<void> pumpChips(
    WidgetTester tester,
    Item item, {
    List<({String typeId, String word, LocalDate? date})> tokens = const [],
  }) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: offloadTheme(),
        locale: const Locale('nl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoredTokenChips(
            item: item,
            tokens: tokens,
            today: LocalDate(2026, 9, 29),
          ),
        ),
      ),
    ),
  );

  final expected = {
    ItemType.task: ('Taak', Icons.check_box_outlined),
    ItemType.idea: ('Idee', Icons.lightbulb_outline),
    ItemType.request: ('Verzoek', Icons.front_hand_outlined),
    ItemType.note: ('Notitie', Icons.description_outlined),
  };

  for (final MapEntry(key: type, value: (name, icon)) in expected.entries) {
    testWidgets('$type shows its icon and name', (tester) async {
      await pumpChips(tester, item(type));
      expect(itemTypeIcon(type), icon);
      final chip = find.byType(ItemTypeChip);
      expect(chip, findsOneWidget);
      expect(
        find.descendant(of: chip, matching: find.byIcon(icon)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip, matching: find.text(name)),
        findsOneWidget,
      );
      expect(tester.getSemantics(chip), matchesSemantics(label: 'type: $name'));
    });
  }

  testWidgets('an item without a type has no type chip', (tester) async {
    await pumpChips(tester, item(null));
    expect(find.byType(ItemTypeChip), findsNothing);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('the type comes before the tokens', (tester) async {
    await pumpChips(
      tester,
      item(ItemType.idea),
      tokens: const [(typeId: 'tag', word: 'renovatie', date: null)],
    );
    final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
    expect(chips, hasLength(2));
    expect(
      tester.getTopLeft(find.byType(ItemTypeChip)).dx,
      lessThan(tester.getTopLeft(find.text('renovatie')).dx),
    );
  });

  testWidgets('the type chip has no colour of its own (DD-017)', (
    tester,
  ) async {
    await pumpChips(tester, item(ItemType.task));
    final chip = tester.widget<Chip>(
      find.descendant(
        of: find.byType(ItemTypeChip),
        matching: find.byType(Chip),
      ),
    );
    expect(chip.backgroundColor, isNull);
    expect(chip.side, isNull);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byType(ItemTypeChip),
              matching: find.byType(Icon),
            ),
          )
          .color,
      isNull,
    );
  });
}
