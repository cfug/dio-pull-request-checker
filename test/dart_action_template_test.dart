import 'dart:io';

import 'package:dio_pull_request_checker/dio_pull_request_checker.dart';
import 'package:dio_pull_request_checker/github.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

const String _changelog = '''
## Unreleased

*None.*

## 1.0.0

- First release.

## 0.0.1

- Initial version.
''';

/// The changelog changed, and only changed the unreleased version.
const String _passedChangelog = '''
## Unreleased

- Add new feature.

## 1.0.0

- First release.

## 0.0.1

- Initial version.
''';

/// The changelog not change.
const String _noPassChangelog = '''
## Unreleased

*None.*

## 1.0.0

- First release.

## 0.0.1

- Initial version.
''';

/// The changelog is change but not only changed the unreleased version.
const String _noPassChangelog2 = '''
## Unreleased

- Fix bug.

## 1.0.0

- First release.
- Add new feature.

## 0.0.1

- Initial version.
''';

/// The changelog is change the 1.0.0 content.
const String _noPassChangelog3 = '''
## Unreleased

*None.*

## 1.0.0

- First release.
- A change in 1.0.0.

## 0.0.1

- Initial version.
''';

void main() {
  test('Test getChangelogMap', () {
    final map = getChangelogMap(_changelog);

    for (final key in map.keys) {
      print('$key: ${map[key]}');
    }

    expect(map.length, 3);

    expect(map['Unreleased'], '*None.*');
    expect(map['1.0.0'], '- First release.');
    expect(map['0.0.1'], '- Initial version.');
  });

  test('Test checkChangeLog', () {
    final result = checkChangeLog(_changelog, _passedChangelog);
    expect(result, isNull);
    expect(checkChangeLog(_changelog, _noPassChangelog), isNotNull);
    expect(checkChangeLog(_changelog, _noPassChangelog2), isNotNull);
    expect(checkChangeLog(_changelog, _noPassChangelog3), isNotNull);
  });

  test('Test GithubContentExt.', () {
    final src1 =
        'IyBDSEFOR0VMT0cKCiMjIDEuMC4wCgpzdXBwb3J0IGNoZWNrIHB1bGwgcmVx\ndWV0cwo=\n';

    final dst1 = '''# CHANGELOG

## 1.0.0

support check pull requets
''';

    expect(src1.decodeHaveNewLineBase64(), dst1);

    final src2 = 'IyMgMS4wLjAKCi0gSW5pdGlhbCB2ZXJzaW9uLgo=\n';
    final dst2 = '''## 1.0.0

- Initial version.
''';

    expect(src2.decodeHaveNewLineBase64(), dst2);
  });

  test('Get content', () async {
    github = GitHub(auth: Authentication.anonymous());

    final owner = 'dart-action';
    final repo = 'dio-pull-request-checker';
    final prNumber = 1;

    final path = 'CHANGELOG.md';

    final content = await getChangeFileContentWithPullRequest(
      owner: owner,
      repo: repo,
      number: prNumber,
      path: path,
    );

    final currentChangeContent = '''# CHANGELOG

## Unreleased

- support check pull requets

## 0.0.1

Init project
''';

    expect(content.after, currentChangeContent);
  });
}
