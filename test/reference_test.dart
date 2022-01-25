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
    repo.free();
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
      final head = repo.head;
      expect(head.type, ReferenceType.direct);
      head.free();

      final ref = Reference.lookup(repo: repo, name: 'HEAD');
      expect(ref.type, ReferenceType.symbolic);
      ref.free();
    });

    test('returns SHA hex of direct reference', () {
      final head = repo.head;
      expect(head.target.sha, lastCommit);
      head.free();
    });

    test('returns SHA hex of symbolic reference', () {
      final ref = Reference.lookup(repo: repo, name: 'HEAD');
      expect(ref.target.sha, lastCommit);
      ref.free();
    });

    test('throws when trying to resolve invalid reference', () {
      expect(
        () => Reference(nullptr).target,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns the full name', () {
      final head = repo.head;
      expect(head.name, 'refs/heads/master');
      head.free();
    });

    test('returns the short name', () {
      final ref = Reference.create(
        repo: repo,
        name: 'refs/remotes/origin/upstream',
        target: repo[lastCommit],
      );

      final head = repo.head;

      expect(head.shorthand, 'master');
      expect(ref.shorthand, 'origin/upstream');

      head.free();
      ref.free();
    });

    test('checks if reference is a local branch', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/feature');
      expect(ref.isBranch, true);
      ref.free();
    });

    test('checks if reference is a note', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(ref.isNote, false);
      ref.free();
    });

    test('checks if reference is a remote branch', () {
      final ref = Reference.lookup(
        repo: repo,
        name: 'refs/remotes/origin/master',
      );
      expect(ref.isRemote, true);
      ref.free();
    });

    test('checks if reference is a tag', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/tags/v0.1');
      expect(ref.isTag, true);
      ref.free();
    });

    test('checks if reflog exists for the reference', () {
      var ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(ref.hasLog, true);

      ref = Reference.lookup(repo: repo, name: 'refs/tags/v0.1');
      expect(ref.hasLog, false);

      ref.free();
    });

    test('ensures updates to the reference will append to its log', () {
      Reference.ensureLog(repo: repo, refName: 'refs/tags/tag');

      final ref = Reference.create(
        repo: repo,
        name: 'refs/tags/tag',
        target: repo[lastCommit],
      );
      final reflog = ref.log;

      expect(reflog.length, 1);

      reflog.free();
      ref.free();
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

      duplicate.free();
      ref.free();
    });

    group('create direct', () {
      test('creates with oid as target', () {
        final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
        final refFromOid = Reference.create(
          repo: repo,
          name: 'refs/tags/from.oid',
          target: ref.target,
        );

        expect(repo.references, contains('refs/tags/from.oid'));

        refFromOid.free();
        ref.free();
      });

      test('creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = Reference.create(
          repo: repo,
          name: 'refs/heads/log.message',
          target: repo[lastCommit],
          logMessage: 'log message',
        );

        final reflog = ref.log;
        final reflogEntry = reflog[0];

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer.name, 'name');
        expect(reflogEntry.committer.email, 'email');

        reflog.free();
        ref.free();
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
        final ref = Reference.create(
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

        ref.free();
        forceRef.free();
      });

      test('throws if name already exists', () {
        final ref = Reference.create(
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

        ref.free();
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

        ref.free();
      });

      test('creates with force flag if name already exists', () {
        final ref = Reference.create(
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

        ref.free();
        forceRef.free();
      });

      test('throws if name already exists', () {
        final ref = Reference.create(
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

        ref.free();
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

        final reflog = ref.log;
        final reflogEntry = reflog[0];

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer.name, 'name');
        expect(reflogEntry.committer.email, 'email');

        reflog.free();
        ref.free();
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
        ref.free();
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
      final reflog = ref.log;
      expect(reflog.last.message, 'commit (initial): init');

      reflog.free();
      ref.free();
    });

    group('set target', () {
      test('sets direct reference with provided oid target', () {
        final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
        ref.setTarget(target: repo[newCommit]);
        expect(ref.target.sha, newCommit);

        ref.free();
      });

      test('sets symbolic target with provided reference name', () {
        final ref = Reference.lookup(repo: repo, name: 'HEAD');
        expect(ref.target.sha, lastCommit);

        ref.setTarget(target: 'refs/heads/feature');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');

        ref.free();
      });

      test('sets target with log message', () {
        final ref = Reference.lookup(repo: repo, name: 'HEAD');
        expect(ref.target.sha, lastCommit);

        repo.setIdentity(name: 'name', email: 'email');
        ref.setTarget(target: 'refs/heads/feature', logMessage: 'log message');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
        final reflog = ref.log;
        expect(reflog.first.message, 'log message');
        expect(reflog.first.committer.name, 'name');
        expect(reflog.first.committer.email, 'email');

        reflog.free();
        ref.free();
      });

      test('throws on invalid target', () {
        final ref = Reference.lookup(repo: repo, name: 'HEAD');
        expect(
          () => ref.setTarget(target: 'refs/heads/invalid~'),
          throwsA(isA<LibGit2Error>()),
        );

        expect(
          () => ref.setTarget(target: Oid(nullptr)),
          throwsA(isA<LibGit2Error>()),
        );

        expect(() => ref.setTarget(target: 0), throwsA(isA<ArgumentError>()));

        ref.free();
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

        ref1.free();
        ref2.free();
      });
    });

    test('checks equality', () {
      final ref1 = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final ref2 = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final ref3 = Reference.lookup(repo: repo, name: 'refs/heads/feature');

      expect(ref1 == ref2, true);
      expect(ref1 != ref2, false);
      expect(ref1 == ref3, false);
      expect(ref1 != ref3, true);

      ref1.free();
      ref2.free();
      ref3.free();
    });

    test('peels to non-tag object when no type is provided', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final commit = Commit.lookup(repo: repo, oid: ref.target);
      final peeled = ref.peel() as Commit;

      expect(peeled.oid, commit.oid);

      peeled.free();
      commit.free();
      ref.free();
    });

    test('peels to object of provided type', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final blob = Blob.lookup(repo: repo, oid: repo['9c78c21']);
      final blobRef = Reference.create(
        repo: repo,
        name: 'refs/tags/blob',
        target: blob.oid,
      );
      final tagRef = Reference.lookup(repo: repo, name: 'refs/tags/v0.2');
      final commit = Commit.lookup(repo: repo, oid: ref.target);
      final tree = commit.tree;

      final peeledCommit = ref.peel(GitObject.commit) as Commit;
      final peeledTree = ref.peel(GitObject.tree) as Tree;
      final peeledBlob = blobRef.peel(GitObject.blob) as Blob;
      final peeledTag = tagRef.peel(GitObject.tag) as Tag;

      expect(peeledCommit.oid, commit.oid);
      expect(peeledTree.oid, tree.oid);
      expect(peeledBlob.content, 'Feature edit\n');
      expect(peeledTag.name, 'v0.2');

      peeledTag.free();
      peeledBlob.free();
      peeledTree.free();
      peeledCommit.free();
      tagRef.free();
      blobRef.free();
      blob.free();
      commit.free();
      tree.free();
      ref.free();
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

    test('returns string representation of Reference object', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(ref.toString(), contains('Reference{'));
      ref.free();
    });
  });
}
