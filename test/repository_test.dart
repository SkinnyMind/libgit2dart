import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const lastCommit = '821ed6e80627b8769d170a293862f9fc60825226';
  const featureCommit = '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Repository', () {
    test('returns config for repository', () {
      expect(
        repo.config['remote.origin.url'].value,
        'git://github.com/SkinnyMind/libgit2dart.git',
      );
    });

    test('returns snapshot of repository config', () {
      expect(
        repo.configSnapshot['remote.origin.url'].value,
        'git://github.com/SkinnyMind/libgit2dart.git',
      );
    });

    test('returns list of commits by walking from provided starting oid', () {
      const log = [
        '821ed6e80627b8769d170a293862f9fc60825226',
        '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
        'c68ff54aabf660fcdd9a2838d401583fe31249e3',
        'fc38877b2552ab554752d9a77e1f48f738cca79b',
        '6cbc22e509d72758ab4c8d9f287ea846b90c448b',
        'f17d0d48eae3aa08cecf29128a35e310c97b3521',
      ];
      final commits = repo.log(oid: repo[lastCommit]);

      for (var i = 0; i < commits.length; i++) {
        expect(commits[i].oid.sha, log[i]);
      }
    });

    group('.discover()', () {
      test('discovers repository', () async {
        final subDir = p.join(tmpDir.path, 'subdir1', 'subdir2');
        await Directory(subDir).create(recursive: true);
        expect(Repository.discover(startPath: subDir), repo.path);
      });

      test('returns empty string when repository not found', () {
        expect(Repository.discover(startPath: Directory.systemTemp.path), '');
      });
    });

    test('returns empty string when there is no namespace', () {
      expect(repo.namespace, isEmpty);
    });

    test('sets and unsets the namespace', () {
      expect(repo.namespace, '');
      repo.setNamespace('some');
      expect(repo.namespace, 'some');
      repo.setNamespace(null);
      expect(repo.namespace, '');
    });

    test('sets working directory', () {
      final tmpWorkDir = Directory(
        p.join(Directory.systemTemp.path, 'tmp_work_dir'),
      );
      tmpWorkDir.createSync();

      repo.setWorkdir(path: tmpWorkDir.path);
      expect(repo.workdir, contains('tmp_work_dir'));

      tmpWorkDir.deleteSync();
    });

    test('throws when trying to set working directory to invalid', () {
      expect(
        () => repo.setWorkdir(path: 'invalid/path'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to get head and error occurs', () {
      File(p.join(repo.path, 'HEAD')).deleteSync();
      expect(() => repo.head, throwsA(isA<LibGit2Error>()));
      expect(() => repo.isHeadDetached, throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to check if branch is unborn and error occurs',
        () {
      File(p.join(repo.path, 'HEAD')).deleteSync();
      expect(() => repo.isBranchUnborn, throwsA(isA<LibGit2Error>()));
    });

    group('setHead', () {
      test('sets head when target is reference', () {
        expect(repo.head.name, 'refs/heads/master');
        expect(repo.head.target.sha, lastCommit);
        repo.setHead('refs/heads/feature');
        expect(repo.head.name, 'refs/heads/feature');
        expect(repo.head.target.sha, featureCommit);
      });

      test('sets head when target is sha hex', () {
        expect(repo.head.target.sha, lastCommit);
        repo.setHead(repo[featureCommit]);
        expect(repo.head.target.sha, featureCommit);
        expect(repo.isHeadDetached, true);
      });

      test('attaches to an unborn branch', () {
        expect(repo.head.name, 'refs/heads/master');
        expect(repo.isBranchUnborn, false);
        repo.setHead('refs/heads/not.there');
        expect(repo.isBranchUnborn, true);
      });

      test('throws when target is invalid', () {
        expect(() => repo.setHead(0), throwsA(isA<ArgumentError>()));
      });

      test('throws when error occurs', () {
        expect(
          () => Repository(nullptr).setHead('refs/heads/feature'),
          throwsA(isA<LibGit2Error>()),
        );
        expect(
          () => Repository(nullptr).setHead(repo['0' * 40]),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns status of a repository', () {
      File(p.join(tmpDir.path, 'new_file.txt')).createSync();
      repo.index.remove('file');
      repo.index.add('new_file.txt');
      expect(
        repo.status,
        {
          'file': {GitStatus.indexDeleted, GitStatus.wtNew},
          'new_file.txt': {GitStatus.indexNew}
        },
      );
    });

    test('throws when trying to get status of bare repository', () {
      final bare = Repository.open(p.join('test', 'assets', 'empty_bare.git'));

      expect(() => bare.status, throwsA(isA<LibGit2Error>()));
    });

    test('cleans up state', () {
      expect(repo.state, GitRepositoryState.none);
      Merge.cherryPick(
        repo: repo,
        commit: Commit.lookup(repo: repo, oid: repo['5aecfa0']),
      );

      expect(repo.state, GitRepositoryState.cherrypick);
      repo.stateCleanup();
      expect(repo.state, GitRepositoryState.none);
    });

    test('throws when trying to clean up state and error occurs', () {
      expect(
        () => Repository(nullptr).stateCleanup(),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns status of a single file for provided path', () {
      repo.index.remove('file');
      expect(
        repo.statusFile('file'),
        {GitStatus.indexDeleted, GitStatus.wtNew},
      );
      expect(repo.statusFile('.gitignore'), {GitStatus.current});
    });

    test('throws when checking status of a single file for invalid path', () {
      expect(() => repo.statusFile('not-there'), throwsA(isA<LibGit2Error>()));
    });

    test('returns default signature', () {
      final config = repo.config;
      config['user.name'] = 'Some Name';
      config['user.email'] = 'some@email.com';

      final signature = repo.defaultSignature;
      expect(signature.name, 'Some Name');
      expect(signature.email, 'some@email.com');
    });

    test('returns attribute value', () {
      expect(repo.getAttribute(path: 'invalid', name: 'not-there'), null);

      File(p.join(repo.workdir, '.gitattributes'))
          .writeAsStringSync('*.dart text\n*.jpg -text\n*.sh eol=lf\n');

      File(p.join(repo.workdir, 'file.dart')).createSync();
      File(p.join(repo.workdir, 'file.sh')).createSync();

      expect(repo.getAttribute(path: 'file.dart', name: 'not-there'), null);
      expect(repo.getAttribute(path: 'file.dart', name: 'text'), true);
      expect(repo.getAttribute(path: 'file.jpg', name: 'text'), false);
      expect(repo.getAttribute(path: 'file.sh', name: 'eol'), 'lf');
    });

    test('returns number of ahead behind commits', () {
      final commit1 = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final commit2 = Commit.lookup(repo: repo, oid: repo['c68ff54']);

      expect(
        repo.aheadBehind(local: commit1.oid, upstream: commit2.oid),
        [4, 0],
      );
      expect(
        repo.aheadBehind(local: commit2.oid, upstream: commit1.oid),
        [0, 4],
      );
      expect(
        repo.aheadBehind(local: commit1.oid, upstream: commit1.oid),
        [0, 0],
      );
    });

    test('manually releases allocated memory', () {
      final repo = Repository.open(tmpDir.path);
      expect(() => repo.free(), returnsNormally);
    });

    test('returns string representation of Repository object', () {
      expect(repo.toString(), contains('Repository{'));
    });

    test('supports value comparison', () {
      expect(repo, equals(Repository.open(tmpDir.path)));
    });
  });
}
