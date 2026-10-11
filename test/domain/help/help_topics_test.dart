import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/help/help_topics.dart';
import 'package:offload/domain/markdown/markdown_document.dart';

/// Help in context (REQ-065, DD-020): the table screen → chapter#anchor and
/// where links in the manual lead.
void main() {
  group('resolveManualLink', () {
    test('a chapter, with or without an anchor', () {
      expect(
        resolveManualLink('README.md', 'today.md'),
        const ManualPlace('today.md'),
      );
      expect(
        resolveManualLink('README.md', 'today.md#groups'),
        const ManualPlace('today.md', 'groups'),
      );
    });

    test('an anchor alone stays in the chapter', () {
      expect(
        resolveManualLink('people.md', '#contact-details'),
        const ManualPlace('people.md', 'contact-details'),
      );
    });

    test('an internet address is only shown', () {
      for (final address in [
        'https://example.org/x',
        'mailto:jan@example.org',
        '//example.org',
      ]) {
        final link = resolveManualLink('README.md', address);
        expect(link, isA<ExternalLink>());
        expect((link! as ExternalLink).address, address);
      }
    });

    test('nothing outside the manual, and nothing for an empty link', () {
      for (final target in [
        '',
        '  ',
        '../SPEC.md',
        'nl/today.md',
        '/etc/hosts',
        'image.png',
      ]) {
        expect(resolveManualLink('README.md', target), isNull, reason: target);
      }
    });
  });

  test('the manual opens in the app language when it exists, else English', () {
    expect(manualLanguageFor('en'), 'en');
    expect(manualLanguageFor('nl'), 'en');
    expect(manualLanguageFor('uk'), 'en');
    expect(manualAsset('en', 'today.md'), 'docs/user-manual/en/today.md');
  });

  group('every help topic reaches the bundled manual', () {
    for (final language in manualLanguages) {
      for (final topic in HelpTopic.values) {
        test('$language: ${topic.name} → ${topic.target}', () {
          final file = File(manualAsset(language, topic.place.chapter));
          expect(file.existsSync(), isTrue, reason: file.path);
          final anchor = topic.place.anchor;
          if (anchor != null) {
            expect(
              headingAnchors(parseMarkdown(file.readAsStringSync())),
              contains(anchor),
            );
          }
        });
      }
    }
  });
}
