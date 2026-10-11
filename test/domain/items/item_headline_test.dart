import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item_headline.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

/// The title and line count of an inbox row (DD-018 point 2).
void main() {
  final registry = InlineTokenRegistry.standard();
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
  ItemHeadline headline(String text) => itemHeadline(text, registry, context);

  test('leaves the prefix tokens out of the title', () {
    expect(headline('Bel Jan over de renovatieplanning @Jan !vr #renovatie'), (
      title: 'Bel Jan over de renovatieplanning',
      moreLines: 0,
    ));
  });

  test('closes the gap a token in the middle leaves', () {
    expect(headline('Bel @Jan morgen').title, 'Bel morgen');
  });

  test('takes the first line and counts the other non-empty lines', () {
    expect(
      headline('RE: Keuring vrijdag\n\nHoi Sam,\r\nkun jij de ketel keuren?\n'),
      (title: 'RE: Keuring vrijdag', moreLines: 2),
    );
  });

  test('skips empty lines at the start', () {
    expect(headline('\n  \nEerste echte regel\ntweede'), (
      title: 'Eerste echte regel',
      moreLines: 1,
    ));
  });

  test('a line of only tokens is shown as typed', () {
    expect(headline('@Jan !vr').title, '@Jan !vr');
  });

  test('escaped and unrecognised prefixes stay', () {
    expect(
      headline(r'Mail \@Jan over #1 en !xyz').title,
      r'Mail \@Jan over #1 en !xyz',
    );
  });

  test('an e-mail address is no person and stays', () {
    expect(headline('Mail jan@example.org').title, 'Mail jan@example.org');
  });

  test('the text after the title line, for the triage card', () {
    expect(
      textAfterFirstLine('\nRE: Keuring\n\nHoi Sam,\r\nGroet, Jan\n'),
      'Hoi Sam,\nGroet, Jan',
    );
    expect(textAfterFirstLine('Eén regel'), '');
    expect(textAfterFirstLine('  '), '');
  });

  test('white space only gives an empty title', () {
    expect(headline('  \n '), (title: '', moreLines: 0));
  });

  test('a link reads as its text, without brackets (T10.9)', () {
    expect(
      headline('Zie [[Offerte kozijnen]] @Jan').title,
      'Zie Offerte kozijnen',
    );
    expect(headline('[[Offerte kozijnen]]').title, 'Offerte kozijnen');
    // A prefix token right before a link never overlaps it.
    expect(headline('Bel @Jan([[Offerte]])').title, 'Bel (Offerte)');
  });
}
