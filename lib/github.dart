import 'dart:convert';

import 'package:github/github.dart';
import 'package:github_action_core/github_action_core.dart';

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

Future<PullRequest> getPullRequest({
  required String owner,
  required String repo,
  required int number,
}) {
  return github.pullRequests.get(RepositorySlug(owner, repo), number);
}

Future<GitCommit?> getPullRequestHeadCommit({
  required String owner,
  required String repo,
  required int prNumber,
}) async {
  final slug = RepositorySlug(owner, repo);
  final pr = await github.pullRequests.get(slug, prNumber);
  final sha = pr.head?.sha;

  if (sha == null) {
    return null;
  }

  final commit = await github.git.getCommit(slug, sha);

  return commit;
}

Future<ChangeFileContent> getChangeFileContentWithPullRequest({
  required String owner,
  required String repo,
  required int number,
  required String path,
}) async {
  final slug = RepositorySlug(owner, repo);
  final pr = await getPullRequest(
    owner: owner,
    number: number,
    repo: repo,
  );

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

  debug('head: $headContent');
  debug('base: $baseContent');

  return ChangeFileContent(
    baseContent.decodeHaveNewLineBase64(),
    headContent.decodeHaveNewLineBase64(),
  );
}

extension GithubContentExt on String {
  String decodeBase64() {
    final list = base64.decode(this);
    return utf8.decode(list);
  }

  String decodeHaveNewLineBase64() {
    return replaceAll('\n', '').decodeBase64();
  }
}
