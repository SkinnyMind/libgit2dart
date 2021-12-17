import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const lastCommit = '821ed6e80627b8769d170a293862f9fc60825226';
  const featureCommit = '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Repository', () {
    test('returns config for repository', () {
      final config = repo.config;
      expect(
        config['remote.origin.url'].value,
        'git://github.com/SkinnyMind/libgit2dart.git',
      );

      config.free();
    });

    test('returns snapshot of repository config', () {
      final snapshot = repo.configSnapshot;
      expect(
        snapshot['remote.origin.url'].value,
        'git://github.com/SkinnyMind/libgit2dart.git',
      );
      snapshot.free();
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

      for (final c in commits) {
        c.free();
      }
    });

    group('.discover()', () {
      test('discovers repository', () async {
        final subDir = '${tmpDir.path}/subdir1/subdir2/';
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

    test('successfully sets and unsets the namespace', () {
      expect(repo.namespace, '');
      repo.setNamespace('some');
      expect(repo.namespace, 'some');
      repo.setNamespace(null);
      expect(repo.namespace, '');
    });

    test('successfully sets working directory', () {
      final tmpWorkDir = Directory('${Directory.systemTemp.path}/tmp_work_dir');
      tmpWorkDir.createSync();

      repo.setWorkdir(path: tmpWorkDir.path);
      expect(repo.workdir, contains('/tmp_work_dir/'));

      tmpWorkDir.deleteSync();
    });

    test('throws when trying to set working directory to invalid', () {
      expect(
        () => repo.setWorkdir(path: 'invalid/path'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to get head and error occurs', () {
      File('${repo.workdir}.git/HEAD').deleteSync();
      expect(() => repo.head, throwsA(isA<LibGit2Error>()));
      expect(() => repo.isHeadDetached, throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to check if branch is unborn and error occurs',
        () {
      File('${repo.workdir}.git/HEAD').deleteSync();
      expect(() => repo.isBranchUnborn, throwsA(isA<LibGit2Error>()));
    });

    group('setHead', () {
      late Reference head;

      setUp(() => head = repo.head);
      tearDown(() => head.free());

      test('successfully sets head when target is reference', () {
        expect(repo.head.name, 'refs/heads/master');
        expect(repo.head.target.sha, lastCommit);
        repo.setHead('refs/heads/feature');
        expect(repo.head.name, 'refs/heads/feature');
        expect(repo.head.target.sha, featureCommit);
      });

      test('successfully sets head when target is sha hex', () {
        expect(repo.head.target.sha, lastCommit);
        repo.setHead(repo[featureCommit]);
        expect(repo.head.target.sha, featureCommit);
        expect(repo.isHeadDetached, true);
      });

      test('successfully attaches to an unborn branch', () {
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

    group('createBlob', () {
      const newBlobContent = 'New blob\n';

      test('successfully creates new blob', () {
        final oid = repo.createBlob(newBlobContent);
        final newBlob = repo.lookupBlob(oid);

        expect(newBlob, isA<Blob>());

        newBlob.free();
      });

      test('successfully creates new blob from file at provided relative path',
          () {
        final oid = repo.createBlobFromWorkdir('feature_file');
        final newBlob = repo.lookupBlob(oid);

        expect(newBlob, isA<Blob>());

        newBlob.free();
      });

      test('successfully creates new blob from file at provided path', () {
        final outsideFile =
            File('${Directory.current.absolute.path}/test/blob_test.dart');
        final oid = repo.createBlobFromDisk(outsideFile.path);
        final newBlob = repo.lookupBlob(oid);

        expect(newBlob, isA<Blob>());

        newBlob.free();
      });
    });

    test('successfully creates tag with provided sha', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = repo['f17d0d48eae3aa08cecf29128a35e310c97b3521'];
      const message = 'init tag\n';

      final oid = repo.createTag(
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        tagger: signature,
        message: message,
      );

      final newTag = repo.lookupTag(oid);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Commit;

      expect(newTag.oid.sha, '131a5eb6b7a880b5096c550ee7351aeae7b95a42');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(tagger, signature);
      expect(newTagTarget.oid, target);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('returns status of a repository', () {
      File('${tmpDir.path}/new_file.txt').createSync();
      final index = repo.index;
      index.remove('file');
      index.add('new_file.txt');
      expect(
        repo.status,
        {
          'file': {GitStatus.indexDeleted, GitStatus.wtNew},
          'new_file.txt': {GitStatus.indexNew}
        },
      );

      index.free();
    });

    test('throws when trying to get status of bare repository', () {
      final bare = Repository.open('test/assets/empty_bare.git');

      expect(() => bare.status, throwsA(isA<LibGit2Error>()));

      bare.free();
    });

    test('cleans up state', () {
      expect(repo.state, GitRepositoryState.none);
      final commit = repo.lookupCommit(repo['5aecfa0']);
      repo.cherryPick(commit);

      expect(repo.state, GitRepositoryState.cherrypick);
      repo.stateCleanup();
      expect(repo.state, GitRepositoryState.none);

      commit.free();
    });

    test('throws when trying to clean up state and error occurs', () {
      expect(
        () => Repository(nullptr).stateCleanup(),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns status of a single file for provided path', () {
      final index = repo.index;
      index.remove('file');
      expect(
        repo.statusFile('file'),
        {GitStatus.indexDeleted, GitStatus.wtNew},
      );
      expect(repo.statusFile('.gitignore'), {GitStatus.current});

      index.free();
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

      signature.free();
      config.free();
    });

    test('returns attribute value', () async {
      expect(repo.getAttribute(path: 'invalid', name: 'not-there'), null);

      final attrFile = await File('${repo.workdir}.gitattributes').create();
      await attrFile.writeAsString('*.dart text\n*.jpg -text\n*.sh eol=lf\n');

      await File('${repo.workdir}file.dart').create();
      await File('${repo.workdir}file.sh').create();

      expect(repo.getAttribute(path: 'file.dart', name: 'not-there'), null);
      expect(repo.getAttribute(path: 'file.dart', name: 'text'), true);
      expect(repo.getAttribute(path: 'file.jpg', name: 'text'), false);
      expect(repo.getAttribute(path: 'file.sh', name: 'eol'), 'lf');
    });

    test('checks if commit is a descendant of another commit', () {
      final commit1 = repo['821ed6e8'];
      final commit2 = repo['78b8bf12'];

      expect(
        repo.descendantOf(commit: commit1, ancestor: commit2),
        true,
      );
      expect(
        repo.descendantOf(commit: commit1, ancestor: commit1),
        false,
      );
      expect(
        repo.descendantOf(commit: commit2, ancestor: commit1),
        false,
      );
    });

    test('throws when trying to check if commit is descendant and error occurs',
        () {
      final commit1 = repo['821ed6e8'];
      final commit2 = repo['78b8bf12'];
      final nullRepo = Repository(nullptr);
      expect(
        () => nullRepo.descendantOf(commit: commit1, ancestor: commit2),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns number of ahead behind commits', () {
      final commit1 = repo.lookupCommit(repo['821ed6e8']);
      final commit2 = repo.lookupCommit(repo['c68ff54a']);

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

      commit1.free();
      commit2.free();
    });

    test('returns string representation of Repository object', () {
      expect(repo.toString(), contains('Repository{'));
    });
  });
}
