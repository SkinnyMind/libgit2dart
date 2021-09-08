import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/merge_testrepo/';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
  });

  tearDown(() async {
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final commit =
            repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'] as Commit;
        final result = repo.mergeAnalysis(commit.id);

        expect(result[0], GitMergeAnalysis.upToDate.value);
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is up to date for provided ref', () {
        final commit =
            repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'] as Commit;
        final result = repo.mergeAnalysis(commit.id, 'refs/tags/v0.1');

        expect(result[0], GitMergeAnalysis.upToDate.value);
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is fast forward', () {
        final theirHead =
            repo['6cbc22e509d72758ab4c8d9f287ea846b90c448b'] as Commit;
        final ffCommit =
            repo['f17d0d48eae3aa08cecf29128a35e310c97b3521'] as Commit;
        final ffBranch = repo.branches.create(
          name: 'ff-branch',
          target: ffCommit,
        );

        final result = repo.mergeAnalysis(theirHead.id, ffBranch.name);

        expect(
          result[0],
          GitMergeAnalysis.fastForward.value + GitMergeAnalysis.normal.value,
        );
        expect(repo.status, isEmpty);

        ffBranch.free();
        ffCommit.free();
        theirHead.free();
      });

      test('is not fast forward and there is no conflicts', () {
        final commit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
        final result = repo.mergeAnalysis(commit.id);

        expect(result[0], GitMergeAnalysis.normal.value);
        expect(repo.status, isEmpty);

        commit.free();
      });
    });
  });
}
