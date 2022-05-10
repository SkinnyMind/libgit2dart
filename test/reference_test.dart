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
  const newCommit = 'c68ff54aabf660fcdd9a2838d401583fe31249e3';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Reference', () {
    test('returns a list', () {
      expect(
        Reference.list(repo),
        [
          'refs/heads/feature',
          'refs/heads/master',
          'refs/notes/commits',
          'refs/remotes/origin/master',
          'refs/tags/v0.1',
          'refs/tags/v0.2',
        ],
      );
    });

    test('throws when trying to get a list of references and error occurs', () {
      expect(
        () => Reference.list(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns correct type of reference', () {
      expect(repo.head.type, ReferenceType.direct);
      expect(
        Reference.lookup(repo: repo, name: 'HEAD').type,
        ReferenceType.symbolic,
      );
    });

    test('returns SHA hex of direct reference', () {
      expect(repo.head.target.sha, lastCommit);
    });

    test('returns SHA hex of symbolic reference', () {
      expect(
        Reference.lookup(repo: repo, name: 'HEAD').target.sha,
        lastCommit,
      );
    });

    test('throws when trying to resolve invalid reference', () {
      expect(
        () => Reference(nullptr).target,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns the full name', () {
      expect(repo.head.name, 'refs/heads/master');
    });

    test('returns the short name', () {
      final ref = Reference.create(
        repo: repo,
        name: 'refs/remotes/origin/upstream',
        target: repo[lastCommit],
      );

      expect(repo.head.shorthand, 'master');
      expect(ref.shorthand, 'origin/upstream');
    });

    test('checks if reference is a local branch', () {
      expect(
        Reference.lookup(repo: repo, name: 'refs/heads/feature').isBranch,
        true,
      );
    });

    test('checks if reference is a note', () {
      expect(
        Reference.lookup(repo: repo, name: 'refs/heads/master').isNote,
        false,
      );
    });

    test('checks if reference is a remote branch', () {
      final ref = Reference.lookup(
        repo: repo,
        name: 'refs/remotes/origin/master',
      );
      expect(ref.isRemote, true);
    });

    test('checks if reference is a tag', () {
      expect(
        Reference.lookup(repo: repo, name: 'refs/tags/v0.1').isTag,
        true,
      );
    });

    test('checks if reflog exists for the reference', () {
      expect(
        Reference.lookup(repo: repo, name: 'refs/heads/master').hasLog,
        true,
      );

      expect(
        Reference.lookup(repo: repo, name: 'refs/tags/v0.1').hasLog,
        false,
      );
    });

    test('ensures updates to the reference will append to its log', () {
      Reference.ensureLog(repo: repo, refName: 'refs/tags/tag');

      final ref = Reference.create(
        repo: repo,
        name: 'refs/tags/tag',
        target: repo[lastCommit],
      );

      expect(ref.log.length, 1);
    });

    test('throws when trying to ensure there is a reflog and error occurs', () {
      expect(
        () => Reference.ensureLog(
          repo: Repository(nullptr),
          refName: 'refs/tags/tag',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('duplicates existing reference', () {
      expect(repo.references.length, 6);

      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final duplicate = ref.duplicate();

      expect(repo.references.length, 6);
      expect(duplicate, equals(ref));
    });

    group('create direct', () {
      test('creates with oid as target', () {
        Reference.create(
          repo: repo,
          name: 'refs/tags/from.oid',
          target: repo.head.target,
        );

        expect(repo.references, contains('refs/tags/from.oid'));
      });

      test('creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = Reference.create(
          repo: repo,
          name: 'refs/heads/log.message',
          target: repo[lastCommit],
          logMessage: 'log message',
        );

        final reflogEntry = ref.log[0];

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer.name, 'name');
        expect(reflogEntry.committer.email, 'email');
      });

      test('throws if target is not valid', () {
        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/invalid',
            target: '78b',
          ),
          throwsA(isA<LibGit2Error>()),
        );

        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/invalid',
            target: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws if name is not valid', () {
        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/invalid~',
            target: repo[lastCommit],
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('creates with force flag if name already exists', () {
        Reference.create(
          repo: repo,
          name: 'refs/tags/test',
          target: repo[lastCommit],
        );

        final forceRef = Reference.create(
          repo: repo,
          name: 'refs/tags/test',
          target: repo[lastCommit],
          force: true,
        );

        expect(forceRef.target.sha, lastCommit);
      });

      test('throws if name already exists', () {
        Reference.create(
          repo: repo,
          name: 'refs/tags/test',
          target: repo[lastCommit],
        );

        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/test',
            target: repo[lastCommit],
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('create symbolic', () {
      test('creates with valid target', () {
        final ref = Reference.create(
          repo: repo,
          name: 'refs/tags/symbolic',
          target: 'refs/heads/master',
        );

        expect(repo.references, contains('refs/tags/symbolic'));
        expect(ref.type, ReferenceType.symbolic);
      });

      test('creates with force flag if name already exists', () {
        Reference.create(
          repo: repo,
          name: 'refs/tags/test',
          target: 'refs/heads/master',
        );

        final forceRef = Reference.create(
          repo: repo,
          name: 'refs/tags/test',
          target: 'refs/heads/master',
          force: true,
        );

        expect(forceRef.target.sha, lastCommit);
        expect(forceRef.type, ReferenceType.symbolic);
      });

      test('throws if name already exists', () {
        Reference.create(
          repo: repo,
          name: 'refs/tags/exists',
          target: 'refs/heads/master',
        );

        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/exists',
            target: 'refs/heads/master',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws if name is not valid', () {
        expect(
          () => Reference.create(
            repo: repo,
            name: 'refs/tags/invalid~',
            target: 'refs/heads/master',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = Reference.create(
          repo: repo,
          name: 'HEAD',
          target: 'refs/heads/feature',
          force: true,
          logMessage: 'log message',
        );

        final reflogEntry = ref.log[0];

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer.name, 'name');
        expect(reflogEntry.committer.email, 'email');
      });
    });

    test('deletes reference', () {
      expect(repo.references, contains('refs/tags/v0.1'));
      Reference.delete(repo: repo, name: 'refs/tags/v0.1');
      expect(repo.references, isNot(contains('refs/tags/v0.1')));
    });

    group('finds', () {
      test('with provided name', () {
        final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
        expect(ref.target.sha, lastCommit);
      });

      test('throws when error occured', () {
        expect(
          () => Reference.lookup(repo: repo, name: 'refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns log for reference', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(ref.log.last.message, 'commit (initial): init');
    });

    group('set target', () {
      test('sets direct reference with provided oid target', () {
        Reference.setTarget(
          repo: repo,
          name: 'refs/heads/master',
          target: repo[newCommit],
        );
        final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
        expect(ref.target.sha, newCommit);
      });

      test('sets symbolic target with provided reference name', () {
        Reference.setTarget(
          repo: repo,
          name: 'HEAD',
          target: 'refs/heads/feature',
        );
        final ref = Reference.lookup(repo: repo, name: 'HEAD');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      });

      test('sets target with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        Reference.setTarget(
          repo: repo,
          name: 'HEAD',
          target: 'refs/heads/feature',
          logMessage: 'log message',
        );

        final ref = Reference.lookup(repo: repo, name: 'HEAD');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
        final logEntry = ref.log.first;
        expect(logEntry.message, 'log message');
        expect(logEntry.committer.name, 'name');
        expect(logEntry.committer.email, 'email');
      });

      test('throws on invalid target', () {
        expect(
          () => Reference.setTarget(
            repo: repo,
            name: 'HEAD',
            target: 'refs/heads/invalid~',
          ),
          throwsA(isA<LibGit2Error>()),
        );

        expect(
          () => Reference.setTarget(
            repo: repo,
            name: 'HEAD',
            target: Oid(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );

        expect(
          () => Reference.setTarget(repo: repo, name: 'HEAD', target: 0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('rename', () {
      test('renames reference', () {
        Reference.rename(
          repo: repo,
          oldName: 'refs/tags/v0.1',
          newName: 'refs/tags/renamed',
        );

        expect(repo.references, contains('refs/tags/renamed'));
        expect(repo.references, isNot(contains('refs/tags/v0.1')));
      });

      test('throws on invalid name', () {
        expect(
          () => Reference.rename(
            repo: repo,
            oldName: 'refs/tags/v0.1',
            newName: 'refs/tags/invalid~',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws if name already exists', () {
        expect(
          () => Reference.rename(
            repo: repo,
            oldName: 'refs/tags/v0.1',
            newName: 'refs/tags/v0.2',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('renames with force flag set to true', () {
        final ref1 = Reference.lookup(repo: repo, name: 'refs/tags/v0.1');
        final ref2 = Reference.lookup(repo: repo, name: 'refs/tags/v0.2');

        expect(ref1.target.sha, '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8');
        expect(ref2.target.sha, 'f0fdbf506397e9f58c59b88dfdd72778ec06cc0c');
        expect(repo.references.length, 6);

        Reference.rename(
          repo: repo,
          oldName: 'refs/tags/v0.1',
          newName: 'refs/tags/v0.2',
          force: true,
        );

        final updatedRef1 = Reference.lookup(
          repo: repo,
          name: 'refs/tags/v0.2',
        );
        expect(
          updatedRef1.target.sha,
          '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
        );
        expect(repo.references, isNot(contains('refs/tags/v0.1')));
        expect(repo.references.length, 5);
      });
    });

    test('peels to non-tag object when no type is provided', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final commit = Commit.lookup(repo: repo, oid: ref.target);
      final peeled = ref.peel() as Commit;

      expect(peeled.oid, commit.oid);
    });

    test('peels to object of provided type', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final blobRef = Reference.create(
        repo: repo,
        name: 'refs/tags/blob',
        target: Blob.lookup(repo: repo, oid: repo['9c78c21']).oid,
      );
      final tagRef = Reference.lookup(repo: repo, name: 'refs/tags/v0.2');
      final commit = Commit.lookup(repo: repo, oid: ref.target);

      final peeledCommit = ref.peel(GitObject.commit) as Commit;
      final peeledTree = ref.peel(GitObject.tree) as Tree;
      final peeledBlob = blobRef.peel(GitObject.blob) as Blob;
      final peeledTag = tagRef.peel(GitObject.tag) as Tag;

      expect(peeledCommit.oid, commit.oid);
      expect(peeledTree.oid, commit.tree.oid);
      expect(peeledBlob.content, 'Feature edit\n');
      expect(peeledTag.name, 'v0.2');
    });

    test('throws when trying to peel and error occurs', () {
      expect(() => Reference(nullptr).peel(), throwsA(isA<LibGit2Error>()));
    });

    test('compresses references', () {
      final packedRefsFile = File(p.join(tmpDir.path, '.git', 'packed-refs'));
      expect(packedRefsFile.existsSync(), false);
      final oldRefs = repo.references;

      Reference.compress(repo);

      expect(packedRefsFile.existsSync(), true);
      final newRefs = repo.references;
      expect(newRefs, oldRefs);
    });

    test('throws when trying to compress and error occurs', () {
      expect(
        () => Reference.compress(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(() => ref.free(), returnsNormally);
    });

    test('returns string representation of Reference object', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(ref.toString(), contains('Reference{'));
    });

    test('supports value comparison', () {
      expect(
        Reference.lookup(repo: repo, name: 'HEAD'),
        equals(Reference.lookup(repo: repo, name: 'refs/heads/master')),
      );
    });
  });
}
