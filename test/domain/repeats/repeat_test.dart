import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v5.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';

/// The date rules of recurring tasks (REQ-061, DD-004 point 14): pure, so
/// every device works out the same series.
void main() {
  LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

  RepeatCompletion done(LocalDate occurrence, LocalDate on) =>
      RepeatCompletion(occurrenceOn: occurrence, completedOn: on);

  group('Rhythm', () {
    test('has a language-neutral code and reads it back', () {
      expect(Rhythm.daily.code, '1D');
      expect(Rhythm.weekly.code, '1W');
      expect(Rhythm.monthly.code, '1M');
      for (final rhythm in [Rhythm.daily, Rhythm.weekly, Rhythm.monthly]) {
        expect(Rhythm.fromCode(rhythm.code), rhythm);
      }
      expect(Rhythm.fromCode('2W'), const Rhythm(RepeatUnit.week, interval: 2));
    });

    test('refuses anything else', () {
      for (final code in ['', 'W', '0D', '1Y', '1w', '1D ', 'x1M']) {
        expect(Rhythm.fromCode(code), isNull, reason: code);
      }
    });
  });

  group('RepeatVocabulary', () {
    const dutch = RepeatVocabulary(
      daily: ['dagelijks'],
      weekly: ['wekelijks'],
      monthly: ['maandelijks'],
    );
    const english = RepeatVocabulary(
      daily: ['daily'],
      weekly: ['weekly'],
      monthly: ['monthly'],
    );
    // Ukrainian, the third language to come (T8.6).
    const ukrainian = RepeatVocabulary(
      daily: ['щодня'],
      weekly: ['щотижня'],
      monthly: ['щомісяця'],
    );

    test('resolves words without case', () {
      expect(dutch.resolve('Wekelijks'), Rhythm.weekly);
      expect(dutch.resolve('DAGELIJKS'), Rhythm.daily);
      expect(dutch.resolve('vrijdag'), isNull);
    });

    test('resolves Cyrillic words without case', () {
      expect(ukrainian.resolve('Щотижня'), Rhythm.weekly);
      expect(ukrainian.resolve('ЩОМІСЯЦЯ'), Rhythm.monthly);
    });

    test('merged, knows the words of every language', () {
      final all = RepeatVocabulary.merge([dutch, english, ukrainian]);
      expect(all.resolve('wekelijks'), Rhythm.weekly);
      expect(all.resolve('weekly'), Rhythm.weekly);
      expect(all.resolve('щодня'), Rhythm.daily);
    });

    test('suggests the rhythms whose word starts with the query', () {
      expect(dutch.suggestions(''), [
        (word: 'dagelijks', rhythm: Rhythm.daily),
        (word: 'wekelijks', rhythm: Rhythm.weekly),
        (word: 'maandelijks', rhythm: Rhythm.monthly),
      ]);
      expect(dutch.suggestions('We'), [
        (word: 'wekelijks', rhythm: Rhythm.weekly),
      ]);
      expect(ukrainian.suggestions('що').length, 3);
      expect(dutch.suggestions('x'), isEmpty);
    });
  });

  group('seriesDate', () {
    test('daily and weekly count days', () {
      expect(seriesDate(d(2026, 10, 6), Rhythm.daily, 3), d(2026, 10, 9));
      expect(seriesDate(d(2026, 10, 6), Rhythm.weekly, 2), d(2026, 10, 20));
    });

    test('ignores summer and winter time: calendar days only', () {
      // Summer time ends in the night of 25 October 2026.
      final days = [
        for (var k = 0; k < 4; k++)
          seriesDate(d(2026, 10, 24), Rhythm.daily, k),
      ];
      expect(days, [
        d(2026, 10, 24),
        d(2026, 10, 25),
        d(2026, 10, 26),
        d(2026, 10, 27),
      ]);
      // And starts on 29 March 2026.
      expect(seriesDate(d(2026, 3, 23), Rhythm.weekly, 1), d(2026, 3, 30));
    });

    test(
      'monthly on the 31st: the last day of shorter months, never drifting',
      () {
        final dates = [
          for (var k = 0; k < 6; k++)
            seriesDate(d(2026, 1, 31), Rhythm.monthly, k),
        ];
        expect(dates, [
          d(2026, 1, 31),
          d(2026, 2, 28),
          d(2026, 3, 31),
          d(2026, 4, 30),
          d(2026, 5, 31),
          d(2026, 6, 30),
        ]);
      },
    );

    test('monthly in a leap year falls on 29 February', () {
      expect(seriesDate(d(2028, 1, 31), Rhythm.monthly, 1), d(2028, 2, 29));
      expect(seriesDate(d(2028, 1, 30), Rhythm.monthly, 1), d(2028, 2, 29));
    });

    test('monthly from 29 February keeps the 29th', () {
      expect(seriesDate(d(2028, 2, 29), Rhythm.monthly, 1), d(2028, 3, 29));
      expect(seriesDate(d(2028, 2, 29), Rhythm.monthly, 12), d(2029, 2, 28));
      expect(seriesDate(d(2028, 2, 29), Rhythm.monthly, 48), d(2032, 2, 29));
    });

    test('monthly over the turn of the year', () {
      expect(seriesDate(d(2026, 11, 30), Rhythm.monthly, 2), d(2027, 1, 30));
      expect(seriesDate(d(2026, 12, 31), Rhythm.monthly, 2), d(2027, 2, 28));
    });
  });

  group('firstSeriesDateAfter', () {
    test('is the anchor while that is still to come', () {
      expect(
        firstSeriesDateAfter(d(2026, 10, 13), Rhythm.weekly, d(2026, 10, 6)),
        d(2026, 10, 13),
      );
    });

    test('is strictly after the given date', () {
      final anchor = d(2026, 9, 8);
      expect(
        firstSeriesDateAfter(anchor, Rhythm.weekly, d(2026, 10, 6)),
        d(2026, 10, 13),
      );
      expect(
        firstSeriesDateAfter(anchor, Rhythm.weekly, d(2026, 10, 7)),
        d(2026, 10, 13),
      );
      expect(
        firstSeriesDateAfter(anchor, Rhythm.weekly, d(2026, 10, 5)),
        d(2026, 10, 6),
      );
    });

    test('monthly from the 31st over short months', () {
      final anchor = d(2026, 1, 31);
      expect(
        firstSeriesDateAfter(anchor, Rhythm.monthly, d(2026, 2, 28)),
        d(2026, 3, 31),
      );
      expect(
        firstSeriesDateAfter(anchor, Rhythm.monthly, d(2026, 2, 27)),
        d(2026, 2, 28),
      );
    });

    test('far after the anchor', () {
      expect(
        firstSeriesDateAfter(d(2020, 1, 1), Rhythm.daily, d(2026, 10, 6)),
        d(2026, 10, 7),
      );
      expect(
        firstSeriesDateAfter(d(2020, 1, 31), Rhythm.monthly, d(2026, 10, 6)),
        d(2026, 10, 31),
      );
    });

    test('with an interval', () {
      const fortnightly = Rhythm(RepeatUnit.week, interval: 2);
      expect(
        firstSeriesDateAfter(d(2026, 9, 1), fortnightly, d(2026, 9, 15)),
        d(2026, 9, 29),
      );
    });
  });

  test('seriesDatesBetween lists the dates in a range', () {
    expect(
      seriesDatesBetween(
        d(2026, 9, 8),
        Rhythm.weekly,
        d(2026, 10, 6),
        d(2026, 10, 27),
      ).toList(),
      [d(2026, 10, 6), d(2026, 10, 13), d(2026, 10, 20), d(2026, 10, 27)],
    );
    expect(
      seriesDatesBetween(
        d(2026, 10, 30),
        Rhythm.daily,
        d(2026, 10, 6),
        d(2026, 10, 31),
      ).toList(),
      [d(2026, 10, 30), d(2026, 10, 31)],
    );
  });

  group('repeatAnchor', () {
    test('the date token first', () {
      expect(
        repeatAnchor(
          dateToken: d(2026, 9, 8),
          records: [done(d(2026, 9, 1), d(2026, 9, 1))],
          entered: d(2026, 8, 1),
        ),
        d(2026, 9, 8),
      );
    });

    test('without one, the earliest completed time', () {
      expect(
        repeatAnchor(
          records: [
            done(d(2026, 2, 28), d(2026, 2, 28)),
            done(d(2026, 1, 31), d(2026, 1, 31)),
          ],
          entered: d(2026, 3, 5),
        ),
        d(2026, 1, 31),
      );
    });

    test('else the day the word entered the text', () {
      expect(
        repeatAnchor(records: const [], entered: d(2026, 10, 6)),
        d(2026, 10, 6),
      );
    });
  });

  group('repeatDue (SPEC Q31)', () {
    final tuesday = d(2026, 9, 8);

    test('is the first time before any completion', () {
      expect(repeatDue(tuesday, Rhythm.weekly, const []), tuesday);
    });

    test('on time: the next date', () {
      expect(
        repeatDue(tuesday, Rhythm.weekly, [done(tuesday, tuesday)]),
        d(2026, 9, 15),
      );
    });

    test('early (Saturday for Tuesday): the Tuesday after', () {
      expect(
        repeatDue(tuesday, Rhythm.weekly, [
          done(d(2026, 9, 15), d(2026, 9, 12)),
        ]),
        d(2026, 9, 22),
      );
    });

    test('late (Thursday for Tuesday): the next Tuesday', () {
      expect(
        repeatDue(tuesday, Rhythm.weekly, [
          done(d(2026, 9, 15), d(2026, 9, 17)),
        ]),
        d(2026, 9, 22),
      );
    });

    test('a daily task left three days: one overdue, then tomorrow', () {
      final anchor = d(2026, 10, 1);
      final records = [done(d(2026, 10, 2), d(2026, 10, 2))];
      // Not done on 3, 4 and 5 October: one date, the 3rd, never three.
      expect(repeatDue(anchor, Rhythm.daily, records), d(2026, 10, 3));
      // Done on the 6th: the next is the 7th.
      expect(
        repeatDue(anchor, Rhythm.daily, [
          ...records,
          done(d(2026, 10, 3), d(2026, 10, 6)),
        ]),
        d(2026, 10, 7),
      );
    });

    test('a later date token wins over older records', () {
      expect(
        repeatDue(d(2026, 11, 3), Rhythm.weekly, [done(tuesday, tuesday)]),
        d(2026, 11, 3),
      );
    });

    test(
      'monthly without a date token from 31 January: 28 Feb, then 31 Mar',
      () {
        // Typed on 31 January without a date: the first time is that day.
        final entered = d(2026, 1, 31);
        var records = <RepeatCompletion>[];
        LocalDate due() => repeatDue(
          repeatAnchor(records: records, entered: entered),
          Rhythm.monthly,
          records,
        );
        expect(due(), d(2026, 1, 31));
        records = [done(d(2026, 1, 31), d(2026, 1, 31))];
        expect(due(), d(2026, 2, 28));
        records = [...records, done(d(2026, 2, 28), d(2026, 2, 28))];
        // The earliest record keeps the 31st; the latest would give the 28th.
        expect(due(), d(2026, 3, 31));
        records = [...records, done(d(2026, 3, 31), d(2026, 3, 31))];
        expect(due(), d(2026, 4, 30));
      },
    );
  });

  test('RepeatCompletion: late days and how far it covers', () {
    final late = done(d(2026, 9, 22), d(2026, 9, 23));
    expect(late.daysLate, 1);
    expect(late.doneThrough, d(2026, 9, 23));
    final early = done(d(2026, 9, 22), d(2026, 9, 19));
    expect(early.daysLate, 0);
    expect(early.doneThrough, d(2026, 9, 22));
  });

  test('repeatsAs: a task or no type yet (decision 6b)', () {
    expect(repeatsAs(null), isTrue);
    expect(repeatsAs(ItemType.task), isTrue);
    expect(repeatsAs(ItemType.idea), isFalse);
    expect(repeatsAs(ItemType.request), isFalse);
    expect(repeatsAs(ItemType.note), isFalse);
  });

  test('ItemRepeat is stored as code and date, and read back', () {
    final repeat = ItemRepeat(Rhythm.weekly, d(2026, 9, 8));
    expect(repeat.encode(), '1W@2026-09-08');
    expect(ItemRepeat.decode('1W@2026-09-08'), repeat);
    for (final bad in [
      null,
      '',
      '1W',
      '1W@',
      'x@2026-09-08',
      '1W@2026-02-30',
    ]) {
      expect(ItemRepeat.decode(bad), isNull, reason: bad);
    }
  });

  group('completionId (SPEC Q33)', () {
    const item = '0199b0a0-1234-7abc-8def-0123456789ab';

    test('is the same for the same item and date, on every device', () {
      expect(
        completionId(item, d(2026, 10, 6)),
        completionId(item, d(2026, 10, 6)),
      );
      expect(isCanonicalUuidV5(completionId(item, d(2026, 10, 6))), isTrue);
    });

    test('differs per date and per item', () {
      expect(
        completionId(item, d(2026, 10, 6)),
        isNot(completionId(item, d(2026, 10, 13))),
      );
      expect(
        completionId(item, d(2026, 10, 6)),
        isNot(
          completionId('0199b0a0-1234-7abc-8def-0123456789ac', d(2026, 10, 6)),
        ),
      );
    });

    test('is fixed: a change would split devices', () {
      expect(
        completionId(item, d(2026, 10, 6)),
        uuidV5(completionIdNamespace, '$item/2026-10-06'),
      );
      expect(completionIdNamespace, '7daf67a7-b5b8-4a94-861e-aabcf1f4baf7');
    });
  });
}
