import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  group('Repository', () {
    late Repository repo;
    test('throws when repository isn\'t found at provided path', () {
      expect(
        () => Repository.open(''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    group('.init()', () {
      final initDir = '${Directory.systemTemp.path}/init_repo/';

      setUp(() async {
        if (await Directory(initDir).exists()) {
          await Directory(initDir).delete(recursive: true);
        } else {
          await Directory(initDir).create();
        }
      });

      tearDown(() async {
        repo.free();
        await Directory(initDir).delete(recursive: true);
      });

      test('successfully creates new bare repo at provided path', () {
        repo = Repository.init(initDir, isBare: true);
        expect(repo.path, initDir);
        expect(repo.isBare, true);
      });

      test('successfully creates new standard repo at provided path', () {
        repo = Repository.init(initDir);
        expect(repo.path, '$initDir.git/');
        expect(repo.isBare, false);
        expect(repo.isEmpty, true);
      });
    });

    group('empty', () {
      group('bare', () {
        setUp(() {
          repo = Repository.open('test/assets/empty_bare.git');
        });

        tearDown(() {
          repo.free();
        });

        test('opens successfully', () {
          expect(repo, isA<Repository>());
        });

        test('checks if it is bare', () {
          expect(repo.isBare, true);
        });

        test('returns path to the repository', () {
          expect(
            repo.path,
            '${Directory.current.path}/test/assets/empty_bare.git/',
          );
        });

        test('returns path to root directory for the repository', () {
          expect(
            repo.commonDir,
            '${Directory.current.path}/test/assets/empty_bare.git/',
          );
        });

        test('returns empty string as path of the working directory', () {
          expect(repo.workdir, '');
        });
      });

      group('standard', () {
        setUp(() {
          repo = Repository.open('test/assets/empty_standard/.gitdir/');
        });

        tearDown(() {
          repo.free();
        });

        test('opens standart repository from working directory successfully',
            () {
          expect(repo, isA<Repository>());
        });

        test('returns path to the repository', () {
          expect(
            repo.path,
            '${Directory.current.path}/test/assets/empty_standard/.gitdir/',
          );
        });

        test('returns path to parent repo\'s .git folder for the repository',
            () {
          expect(
            repo.commonDir,
            '${Directory.current.path}/test/assets/empty_standard/.gitdir/',
          );
        });

        test('checks if it is empty', () {
          expect(repo.isEmpty, true);
        });

        test('checks if head is detached', () {
          expect(repo.isHeadDetached, false);
        });

        test('checks if branch is unborn', () {
          expect(repo.isBranchUnborn, true);
        });

        test('successfully sets identity ', () {
          repo.setIdentity(name: 'name', email: 'email@email.com');
          expect(repo.identity, {'name': 'email@email.com'});
        });

        test('successfully unsets identity', () {
          repo.setIdentity(name: null, email: null);
          expect(repo.identity, isEmpty);
        });

        test('checks if shallow clone', () {
          expect(repo.isShallow, false);
        });

        test('checks if linked work tree', () {
          expect(repo.isWorktree, false);
        });

        test('returns path to working directory', () {
          expect(
            repo.workdir,
            '${Directory.current.path}/test/assets/empty_standard/',
          );
        });
      });
    });

    group('testrepo', () {
      const lastCommit = '821ed6e80627b8769d170a293862f9fc60825226';
      const featureCommit = '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4';

      final tmpDir = '${Directory.systemTemp.path}/testrepo/';

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

      test('returns config for repository', () {
        final config = repo.config;
        expect(config['remote.origin.url'],
            'git://github.com/SkinnyMind/libgit2dart.git');

        config.free();
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
        final commits = repo.log(lastCommit);

        for (var i = 0; i < commits.length; i++) {
          expect(commits[i].id.sha, log[i]);
        }

        for (var c in commits) {
          c.free();
        }
      });

      group('.discover()', () {
        test('discovers repository', () async {
          final subDir = '${tmpDir}subdir1/subdir2/';
          await Directory(subDir).create(recursive: true);
          expect(Repository.discover(subDir), repo.path);
        });

        test('returns empty string when repository not found', () {
          expect(Repository.discover(Directory.systemTemp.path), '');
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
        final tmpWorkDir = '${Directory.systemTemp.path}/tmp_work_dir/';
        Directory(tmpWorkDir).createSync();

        repo.setWorkdir(tmpWorkDir);
        expect(repo.workdir, tmpWorkDir);

        Directory(tmpWorkDir).deleteSync();
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
          repo.setHead(featureCommit);
          expect(repo.head.target.sha, featureCommit);
          expect(repo.isHeadDetached, true);
        });

        test('successfully sets head when target is short sha hex', () {
          expect(repo.head.target.sha, lastCommit);
          repo.setHead(featureCommit.substring(0, 5));
          expect(repo.head.target.sha, featureCommit);
          expect(repo.isHeadDetached, true);
        });

        test('successfully attaches to an unborn branch', () {
          expect(repo.head.name, 'refs/heads/master');
          expect(repo.isBranchUnborn, false);
          repo.setHead('refs/heads/not.there');
          expect(repo.isBranchUnborn, true);
        });
      });

      group('createBlob', () {
        const newBlobContent = 'New blob\n';

        test('successfully creates new blob', () {
          final oid = repo.createBlob(newBlobContent);
          final newBlob = repo[oid.sha] as Blob;

          expect(newBlob, isA<Blob>());

          newBlob.free();
        });

        test(
            'successfully creates new blob from file at provided relative path',
            () {
          final oid = repo.createBlobFromWorkdir('feature_file');
          final newBlob = repo[oid.sha] as Blob;

          expect(newBlob, isA<Blob>());

          newBlob.free();
        });

        test('successfully creates new blob from file at provided path', () {
          final outsideFile =
              File('${Directory.current.absolute.path}/test/blob_test.dart');
          final oid = repo.createBlobFromDisk(outsideFile.path);
          final newBlob = repo[oid.sha] as Blob;

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
        const target = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
        const message = 'init tag\n';

        final oid = Tag.create(
          repository: repo,
          tagName: tagName,
          target: target,
          targetType: GitObject.commit,
          tagger: signature,
          message: message,
        );

        final newTag = repo[oid.sha] as Tag;
        final tagger = newTag.tagger;
        final newTagTarget = newTag.target;

        expect(newTag.id.sha, '131a5eb6b7a880b5096c550ee7351aeae7b95a42');
        expect(newTag.name, tagName);
        expect(newTag.message, message);
        expect(tagger, signature);
        expect(newTagTarget.id.sha, target);

        newTag.free();
        newTagTarget.free();
        signature.free();
      });
    });
  });
}
