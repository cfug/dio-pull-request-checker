import 'dart:convert';

import 'package:github/github.dart';

late GitHub github;

Future<List<PullRequestFile>> getPullRequestFiles({
  required String owner,
  required String repo,
  required int number,
}) async {
  final slug = RepositorySlug(owner, repo);
  return github.pullRequests.listFiles(slug, number).toList();
}

Future<void> sendComment({
  required String owner,
  required String repo,
  required int number,
  required String body,
}) async {
  final slug = RepositorySlug(owner, repo);
  await github.issues.createComment(slug, number, body);
}

class ChangeFileContent {
  final String before;
  final String after;

  const ChangeFileContent(this.before, this.after);
}

Future<ChangeFileContent> getChangeFileContentWithPullRequest({
  required String owner,
  required String repo,
  required int number,
  required String path,
}) async {
  final slug = RepositorySlug(owner, repo);
  final pr = await github.pullRequests.get(slug, number);

  final head = pr.head?.sha;
  final base = pr.base?.sha;

  if (head == null || base == null) {
    throw Exception('Cannot get head or base commit');
  }

  // Get the content of the head and base
  final headContents =
      await github.repositories.getContents(slug, path, ref: head);
  final headContent = headContents.file?.content;

  final baseContents =
      await github.repositories.getContents(slug, path, ref: base);
  final baseContent = baseContents.file?.content;

  if (headContent == null || baseContent == null) {
    throw Exception('Cannot get head or base content');
  }

  return ChangeFileContent(
    baseContent.decodeBase64(),
    headContent.decodeBase64(),
  );
}

extension _StringExt on String {
  String decodeBase64() {
    final list = base64.decode(this);
    return utf8.decode(list);
  }
}
