import 'inline_token.dart';

/// [text] without the tokens [matches] (for example the repeat words, for
/// *Herhaling stoppen*, DD-018 point 18), each with one space next to it,
/// so no double space or trailing space is left behind. The rest of the
/// text stays exactly as typed (DD-004 point 1: a user edit, through a
/// button).
String withoutTokens(String text, Iterable<TokenMatch> matches) {
  final ordered = matches.toList()..sort((a, b) => b.start.compareTo(a.start));
  var result = text;
  for (final match in ordered) {
    var start = match.start;
    var end = match.end;
    if (start > 0 && result[start - 1] == ' ') {
      start--;
    } else if (end < result.length && result[end] == ' ') {
      end++;
    }
    result = result.replaceRange(start, end, '');
  }
  return result;
}
