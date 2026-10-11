import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item_share_text.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

/// Sharing an item as text (REQ-043, DD-014).
void main() {
  // Monday 28 September 2026.
  final context = ParseContext(
    today: LocalDate(2026, 9, 28),
    dates: DateVocabulary(
      today: const ['vandaag'],
      tomorrow: const ['morgen'],
      dayAfterTomorrow: const ['overmorgen'],
      nextWeek: const ['volgendeweek'],
      weekdays: const [
        ['ma'],
        ['di'],
        ['wo'],
        ['do'],
        ['vr'],
        ['za'],
        ['zo'],
      ],
    ),
  );
  final renderer = ItemShareRenderer(
    registry: InlineTokenRegistry.standard(),
    formatDate: (date) => '<$date>',
  );
  String render(
    String text, {
    Map<String, LocalDate> knownDates = const {},
    bool includeTags = false,
  }) => renderer.render(
    text,
    context: context,
    knownDates: knownDates,
    includeTags: includeTags,
  );

  test('writes a person without the prefix, as typed', () {
    expect(render('Bel @Jan over de markt'), 'Bel Jan over de markt');
    expect(render('Vraag (@jj), graag'), 'Vraag (jj), graag');
  });

  test('writes a date out', () {
    expect(render('Offerte af !vr'), 'Offerte af <2026-10-02>');
    expect(render('Klaar !12-10.'), 'Klaar <2026-10-12>.');
  });

  test('a date word keeps the date it got when it was typed', () {
    expect(
      render('Bellen !morgen', knownDates: {'morgen': LocalDate(2026, 9, 20)}),
      'Bellen <2026-09-20>',
    );
  });

  test('leaves tags out by default, without gaps', () {
    expect(render('Idee #renovatie voor later'), 'Idee voor later');
    expect(render('Idee #renovatie'), 'Idee');
    expect(render('#renovatie idee'), 'idee');
    expect(render('Idee #renovatie.'), 'Idee.');
    expect(render('Idee #a #b'), 'Idee');
    expect(render('Eerste #a\nTweede'), 'Eerste\nTweede');
  });

  test('keeps tags as typed when they are included', () {
    expect(
      render('Idee #renovatie voor @Jan', includeTags: true),
      'Idee #renovatie voor Jan',
    );
  });

  test('drops the escape backslash, keeps the sign', () {
    expect(render(r'Mail \@Jan'), 'Mail @Jan');
    expect(render(r'Pad C:\#map'), r'Pad C:\#map');
  });

  test('keeps what is not a token', () {
    expect(
      render('jan@example.org om 10:00 #1'),
      'jan@example.org om 10:00 #1',
    );
    expect(
      render('  Regel een\n\n  ingesprongen  '),
      'Regel een\n\n  ingesprongen',
    );
  });

  test('a text of only tags becomes empty', () {
    expect(render('#renovatie #idee'), '');
  });

  group('shareSubject', () {
    test('is the first non-empty line, trimmed', () {
      expect(shareSubject('\n  Onderwerp  \nTekst'), 'Onderwerp');
      expect(shareSubject('Een regel'), 'Een regel');
      expect(shareSubject('  \n '), '');
    });
  });

  test('a link reads as its text (T10.9)', () {
    expect(
      render('Zie [[Offerte kozijnen]], graag'),
      'Zie Offerte kozijnen, graag',
    );
  });

  group('as typed, for Offload (T2.7a)', () {
    final typedContext = ParseContext(
      today: context.today,
      dates: context.dates,
      repeats: const RepeatVocabulary(weekly: ['wekelijks']),
    );
    String asTyped(
      String text, {
      Map<String, LocalDate> knownDates = const {},
    }) => renderer.renderAsTyped(
      text,
      context: typedContext,
      knownDates: knownDates,
    );

    test('every token stays as typed', () {
      expect(
        asTyped('Bel @Jan over #tuin ^verbouwing *hoog [[Offerte kozijnen]]'),
        'Bel @Jan over #tuin ^verbouwing *hoog [[Offerte kozijnen]]',
      );
    });

    test('a date word becomes its fixed date, from the stored one', () {
      expect(asTyped('Offerte af !vr'), 'Offerte af !2-10-2026');
      expect(
        asTyped(
          'Bellen !morgen graag',
          knownDates: {'morgen': LocalDate(2026, 9, 20)},
        ),
        'Bellen !20-9-2026 graag',
      );
      expect(asTyped('Klaar !12-10.'), 'Klaar !12-10-2026.');
    });

    test('a repeat word stays; its date becomes fixed', () {
      expect(
        asTyped('Hardlopen !wekelijks !vr'),
        'Hardlopen !wekelijks !2-10-2026',
      );
    });

    test('escapes, other lines and Cyrillic stay', () {
      expect(
        asTyped(
          r'Mail \@Jan'
          '\nПодзвонити в Київ !vr',
        ),
        r'Mail \@Jan'
        '\nПодзвонити в Київ !2-10-2026',
      );
    });

    test('the fixed date reads back as the same date', () {
      final text = asTyped('Bellen !morgen');
      final match = InlineTokenRegistry.standard()
          .parse(text, typedContext)
          .single;
      expect(match.value, LocalDate(2026, 9, 29));
    });
  });
}
