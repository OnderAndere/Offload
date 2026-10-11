import '../tokens/token_processing.dart';
import 'birthday.dart';

/// A live person (DD-015): a name and the other names `@` finds them by.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.birthday,
    this.note,
    this.organisation,
    this.jobTitle,
  });

  final String id;
  final String name;

  /// The live aliases, by name.
  final List<String> aliases;

  /// The profile (REQ-031, DD-012), both optional.
  final Birthday? birthday;

  /// Free Markdown note, shown as plain text for now (DD-018 point 7).
  final String? note;

  /// Where the person works and as what (REQ-038), both optional.
  final String? organisation;
  final String? jobTitle;

  /// Whether [query] occurs in the name or an alias, ignoring case with
  /// Unicode rules (the filter of the people list, DD-018 point 7).
  bool matches(String query) {
    final key = nameKey(query);
    return nameKey(name).contains(key) ||
        aliases.any((alias) => nameKey(alias).contains(key));
  }
}

/// The initials of [name], at most two, for a person's badge: "Jan
/// Bakker" → "JB", "Сергей Иванов" → "СИ".
String initialsOf(String name) {
  final words = [
    for (final w in name.trim().split(RegExp(r'\s+')))
      if (w.isNotEmpty) w,
  ];
  if (words.isEmpty) return '';
  return [
    String.fromCharCode(words.first.runes.first),
    if (words.length > 1) String.fromCharCode(words.last.runes.first),
  ].join().toUpperCase();
}

/// Why a change to a person is refused (DD-018 point 7). The screen turns
/// the reason into a message.
enum PersonProblem {
  /// The name is empty.
  emptyName,

  /// Another live person has this name or alias; joining them is merging
  /// (T3.2b).
  nameTaken,

  /// The person is deleted or unknown.
  notAvailable,

  /// A person cannot be merged into themselves.
  samePerson,
}

class PersonException implements Exception {
  const PersonException(this.problem);

  final PersonProblem problem;

  @override
  String toString() => 'PersonException(${problem.name})';
}
