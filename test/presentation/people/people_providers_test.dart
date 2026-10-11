import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/presentation/people/people_providers.dart';

/// The people providers read a merged person as the one they went into
/// (DD-015), also while the streams arrive in any order.
void main() {
  ProviderContainer container({
    required Stream<List<Person>> people,
    required Stream<Map<String, String>> merged,
  }) {
    final c = ProviderContainer(
      overrides: [
        peopleProvider.overrideWith((ref) => people),
        mergedIntoProvider.overrideWith((ref) => merged),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('the merged map before the people: no crash, nothing yet', () async {
    final people = StreamController<List<Person>>();
    addTearDown(people.close);
    final c = container(
      people: people.stream,
      merged: Stream.value({'old': 'jan'}),
    );
    c.listen(peopleByIdProvider, (_, _) {});
    await pumpEventQueue();
    expect(c.read(peopleByIdProvider), isEmpty);
    expect(c.read(personResolverProvider)('old'), 'old');

    people.add(const [Person(id: 'jan', name: 'Jan')]);
    await pumpEventQueue();
    expect(c.read(peopleByIdProvider)['old']?.name, 'Jan');
    expect(c.read(personResolverProvider)('old'), 'jan');
  });
}
