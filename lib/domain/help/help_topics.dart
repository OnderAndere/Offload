/// Help in context (REQ-065, DD-020): which part of the user manual each
/// screen opens. The one table of screen → `chapter.md#anchor`; a test
/// checks every entry against the bundled chapters, so a renamed heading
/// cannot silently break help.
enum HelpTopic {
  contents('README.md'),
  today('today.md'),
  inbox('capturing.md#the-inbox'),
  capture('capturing.md#capturing-a-thought'),
  syntax('capturing.md#people-tags-dates-projects-and-priority-in-your-text'),
  item('item-detail.md'),
  triage('triage.md'),
  weeklyReview('weekly-review.md'),
  projects('projects.md'),
  project('projects.md#opening-a-project'),
  people('people.md'),
  person('people.md#opening-a-person'),
  insights('insights.md'),
  search('searching.md'),
  settings('settings.md');

  const HelpTopic(this.target);

  /// The chapter, optionally with `#anchor`, as a link in the manual.
  final String target;

  /// Where [target] goes.
  ManualPlace get place =>
      resolveManualLink('README.md', target)! as ManualPlace;
}

/// The languages the manual is written in (DD-020: English is the base; a
/// Dutch translation follows with T8.5).
const manualLanguages = ['en'];

/// The manual's language for an app in [appLanguage]: the same when the
/// manual exists in it, otherwise English.
String manualLanguageFor(String appLanguage) =>
    manualLanguages.contains(appLanguage) ? appLanguage : 'en';

/// The asset path of [chapter] in the manual in [language].
String manualAsset(String language, String chapter) =>
    'docs/user-manual/$language/$chapter';

/// Where a link in the manual leads.
sealed class ManualLink {
  const ManualLink();
}

/// A chapter of the manual, at the heading with [anchor] or at the top.
final class ManualPlace extends ManualLink {
  const ManualPlace(this.chapter, [this.anchor]);

  final String chapter;
  final String? anchor;

  @override
  bool operator ==(Object other) =>
      other is ManualPlace &&
      other.chapter == chapter &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(chapter, anchor);

  @override
  String toString() =>
      'ManualPlace($chapter${anchor == null ? '' : '#$anchor'})';
}

/// An address outside the manual: shown, never opened (REQ-003).
final class ExternalLink extends ManualLink {
  const ExternalLink(this.address);

  final String address;
}

/// Where [target], a link written in [chapter], leads; null for a link that
/// leads nowhere the app may go (empty, or a file outside the manual).
ManualLink? resolveManualLink(String chapter, String target) {
  final link = target.trim();
  if (link.isEmpty) return null;
  if (_scheme.hasMatch(link) || link.startsWith('//')) {
    return ExternalLink(link);
  }
  final hash = link.indexOf('#');
  final file = hash < 0 ? link : link.substring(0, hash);
  final anchor = hash < 0 ? null : link.substring(hash + 1);
  final name = file.isEmpty ? chapter : file;
  if (!_chapterName.hasMatch(name)) return null;
  return ManualPlace(name, anchor == null || anchor.isEmpty ? null : anchor);
}

final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
final _chapterName = RegExp(r'^[A-Za-z0-9_-]+\.md$');
