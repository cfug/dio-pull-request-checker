import 'dart:io';

import 'package:dio_pull_request_checker/dio_pull_request_checker.dart';
import 'package:dio_pull_request_checker/github.dart';
import 'package:github/github.dart';
import 'package:github_action_context/github_action_context.dart';
import 'package:github_action_core/github_action_core.dart';

void injectGithub() {
  // Get the token from env
  final token = Platform.environment['WORKFLOW_TOKEN'];
  if (token == null) {
    setFailed('The input github-token is required');
  }
  github = GitHub(auth: Authentication.withToken(token));
}

Future<void> main(List<String> arguments) async {
  // 1. Check if the current workflow run is a pull request
  final pr = context.payload.pullRequest;
  final number = pr?.number;
  if (pr == null || number == null) {
    print('This is not a pull request, skipping');
    return;
  }

  final repository = context.payload.repository;
  if (repository == null) {
    print('Cannot get repository information, skipping');
    return;
  }

  injectGithub();

  final owner = repository.owner.login;
  final repo = repository.name;
  final latestCommitIdShort = context.payload['after'];
  final comment =
      '''The PR applies invalid `CHANGELOG.md` (latest check @$latestCommitIdShort). Please correct it according to the [Wiki](https://github.com/cfug/dio/wiki/Releasing-a-new-version-of-packages#before-start).

> PR 更改了 `CHANGELOG.md`（最新检查的提交 $latestCommitIdShort）但内容不符合格式。请参考 [Wiki](https://github.com/cfug/dio/wiki/Releasing-a-new-version-of-packages#before-start) 修改。

''';

  // 2. Get all changed files
  final files = await getPullRequestFiles(
    owner: owner,
    repo: repo,
    number: number,
  );

  // 3. Check if the changed files contain changelog
  final changelogFiles = files.where((file) {
    final filename = file.filename; // The file name is path
    return filename != null && filename.contains('CHANGELOG.md');
  }).toList();

  if (changelogFiles.isEmpty) {
    // 4. If not, fail the workflow, before that, we add comments to the pull request
    // Get the latest commit id
    notice('No CHANGELOG.md found in the pull request, please add one.');
    await sendComment(owner: owner, repo: repo, number: number, body: comment);
    setFailed('No CHANGELOG.md found in the pull request, please add one.');
  }

  // 5. Have changelog, check if the content is valid
  for (final file in changelogFiles) {
    final content = await getChangeFileContentWithPullRequest(
      owner: owner,
      repo: repo,
      number: number,
      path: file.filename!,
    );

    final before = content.before;
    final after = content.after;

    final checkMsg = checkChangeLog(before, after);
    if (checkMsg != null) {
      // 6. If not, fail the workflow, before that, we add comments to the pull request
      // Get the latest commit id
      notice(checkMsg);
      await sendComment(
        owner: owner,
        repo: repo,
        number: number,
        body: comment,
      );
      setFailed(checkMsg);
    }
  }
}
