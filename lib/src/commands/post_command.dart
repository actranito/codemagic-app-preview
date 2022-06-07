import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:codemagic_app_preview/src/builds/artifact_links_parser.dart';
import 'package:codemagic_app_preview/src/comment/comment_builder.dart';
import 'package:codemagic_app_preview/src/comment/comment_poster.dart';
import 'package:codemagic_app_preview/src/environment_variable/environment_variable_accessor.dart';
import 'package:codemagic_app_preview/src/github/github_api_repository.dart';
import 'package:http/http.dart';

class PostCommand extends Command {
  PostCommand({
    Client? httpClient,
    this.environmentVariableAccessor =
        const SystemEnvironmentVariableAccessor(),
  }) : this.httpClient = httpClient ?? Client() {
    argParser
      ..addOption('owner', abbr: 'o')
      ..addOption('repo', abbr: 'r')
      ..addOption('token', abbr: 't');
  }

  final Client httpClient;
  final EnvironmentVariableAccessor environmentVariableAccessor;

  @override
  String get description =>
      'Post a new comment or edits the existing comment with the links to the app previews';

  @override
  String get name => 'post';

  Future<void> run() async {
    final String? token = argResults?['token'];
    if (token == null) {
      stderr.writeln(
          'The token for the GitHub API is not set. Please set the token with the --token option.');
      exitCode = 1;
      return;
    }

    final builds = ArtifactLinksParser(environmentVariableAccessor).getBuilds();

    final comment = CommentBuilder(environmentVariableAccessor).build(builds);
    final gitHubApi = GitHubApiRepository(
      token: argResults!['token'],
      httpClient: httpClient,
      owner: argResults!['owner'],
      repository: argResults!['repo'],
    );

    final pullRequestId =
        environmentVariableAccessor.get('CM_PULL_REQUEST_NUMBER');
    await CommentPoster(gitHubApi)
        .post(comment: comment, pullRequestId: pullRequestId);
  }
}
