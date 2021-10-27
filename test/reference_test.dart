import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const lastCommit = '821ed6e80627b8769d170a293862f9fc60825226';
  const newCommit = 'c68ff54aabf660fcdd9a2838d401583fe31249e3';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Reference', () {
    test('returns a list', () {
      expect(
        repo.references,
        [
          'refs/heads/feature',
          'refs/heads/master',
          'refs/notes/commits',
          'refs/tags/v0.1',
          'refs/tags/v0.2',
        ],
      );
    });

    test('throws when trying to get a list of references and error occurs', () {
      expect(
        () => Repository(nullptr).references,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns correct type of reference', () {
      final head = repo.head;
      expect(head.type, ReferenceType.direct);
      head.free();

      final ref = repo.lookupReference('HEAD');
      expect(ref.type, ReferenceType.symbolic);
      ref.free();
    });

    test('returns SHA hex of direct reference', () {
      final head = repo.head;
      expect(head.target.sha, lastCommit);
      head.free();
    });

    test('returns SHA hex of symbolic reference', () {
      final ref = repo.lookupReference('HEAD');
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
      final ref = repo.createReference(
        name: 'refs/remotes/origin/master',
        target: repo[lastCommit],
      );

      final head = repo.head;

      expect(head.shorthand, 'master');
      expect(ref.shorthand, 'origin/master');

      head.free();
      ref.free();
    });

    test('checks if reference is a local branch', () {
      final ref = repo.lookupReference('refs/heads/feature');
      expect(ref.isBranch, true);
      ref.free();
    });

    test('checks if reference is a note', () {
      final ref = repo.lookupReference('refs/heads/master');
      expect(ref.isNote, false);
      ref.free();
    });

    test('checks if reference is a remote branch', () {
      final ref = repo.createReference(
        name: 'refs/remotes/origin/master',
        target: repo[lastCommit],
      );

      expect(ref.isRemote, true);

      ref.free();
    });

    test('checks if reference is a tag', () {
      final ref = repo.lookupReference('refs/tags/v0.1');
      expect(ref.isTag, true);
      ref.free();
    });

    test('checks if reflog exists for the reference', () {
      var ref = repo.lookupReference('refs/heads/master');
      expect(ref.hasLog, true);

      ref = repo.lookupReference('refs/tags/v0.1');
      expect(ref.hasLog, false);

      ref.free();
    });

    group('create direct', () {
      test('successfully creates with Oid as target', () {
        final ref = repo.lookupReference('refs/heads/master');
        final refFromOid = repo.createReference(
          name: 'refs/tags/from.oid',
          target: ref.target,
        );

        expect(repo.references, contains('refs/tags/from.oid'));

        refFromOid.free();
        ref.free();
      });

      test('successfully creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = repo.createReference(
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
          () => repo.createReference(
            name: 'refs/tags/invalid',
            target: '78b',
          ),
          throwsA(isA<LibGit2Error>()),
        );

        expect(
          () => repo.createReference(
            name: 'refs/tags/invalid',
            target: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws if name is not valid', () {
        expect(
          () => repo.createReference(
            name: 'refs/tags/invalid~',
            target: repo[lastCommit],
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully creates with force flag if name already exists', () {
        final ref = repo.createReference(
          name: 'refs/tags/test',
          target: repo[lastCommit],
        );

        final forceRef = repo.createReference(
          name: 'refs/tags/test',
          target: repo[lastCommit],
          force: true,
        );

        expect(forceRef.target.sha, lastCommit);

        ref.free();
        forceRef.free();
      });

      test('throws if name already exists', () {
        final ref = repo.createReference(
          name: 'refs/tags/test',
          target: repo[lastCommit],
        );

        expect(
          () => repo.createReference(
            name: 'refs/tags/test',
            target: repo[lastCommit],
          ),
          throwsA(isA<LibGit2Error>()),
        );

        ref.free();
      });
    });

    group('create symbolic', () {
      test('successfully creates with valid target', () {
        final ref = repo.createReference(
          name: 'refs/tags/symbolic',
          target: 'refs/heads/master',
        );

        expect(repo.references, contains('refs/tags/symbolic'));
        expect(ref.type, ReferenceType.symbolic);

        ref.free();
      });

      test('successfully creates with force flag if name already exists', () {
        final ref = repo.createReference(
          name: 'refs/tags/test',
          target: 'refs/heads/master',
        );

        final forceRef = repo.createReference(
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
        final ref = repo.createReference(
          name: 'refs/tags/exists',
          target: 'refs/heads/master',
        );

        expect(
          () => repo.createReference(
            name: 'refs/tags/exists',
            target: 'refs/heads/master',
          ),
          throwsA(isA<LibGit2Error>()),
        );

        ref.free();
      });

      test('throws if name is not valid', () {
        expect(
          () => repo.createReference(
            name: 'refs/tags/invalid~',
            target: 'refs/heads/master',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = repo.createReference(
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

    test('successfully deletes reference', () {
      expect(repo.references, contains('refs/tags/v0.1'));

      repo.deleteReference('refs/tags/v0.1');
      expect(repo.references, isNot(contains('refs/tags/v0.1')));
    });

    group('finds', () {
      test('with provided name', () {
        final ref = repo.lookupReference('refs/heads/master');
        expect(ref.target.sha, lastCommit);
        ref.free();
      });

      test('throws when error occured', () {
        expect(
          () => repo.lookupReference('refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns log for reference', () {
      final ref = repo.lookupReference('refs/heads/master');
      final reflog = ref.log;
      expect(reflog.last.message, 'commit (initial): init');

      reflog.free();
      ref.free();
    });

    group('set target', () {
      test('successfully sets direct reference with provided Oid target', () {
        final ref = repo.lookupReference('refs/heads/master');
        ref.setTarget(target: repo[newCommit]);
        expect(ref.target.sha, newCommit);

        ref.free();
      });

      test('successfully sets symbolic target with provided reference name',
          () {
        final ref = repo.lookupReference('HEAD');
        expect(ref.target.sha, lastCommit);

        ref.setTarget(target: 'refs/heads/feature');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');

        ref.free();
      });

      test('successfully sets target with log message', () {
        final ref = repo.lookupReference('HEAD');
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
        final ref = repo.lookupReference('HEAD');
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
      test('successfully renames reference', () {
        repo.renameReference(
          oldName: 'refs/tags/v0.1',
          newName: 'refs/tags/renamed',
        );

        expect(repo.references, contains('refs/tags/renamed'));
        expect(repo.references, isNot(contains('refs/tags/v0.1')));
      });

      test('throws on invalid name', () {
        expect(
          () => repo.renameReference(
            oldName: 'refs/tags/v0.1',
            newName: 'refs/tags/invalid~',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws if name already exists', () {
        expect(
          () => repo.renameReference(
            oldName: 'refs/tags/v0.1',
            newName: 'refs/tags/v0.2',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully renames with force flag set to true', () {
        final ref1 = repo.lookupReference('refs/tags/v0.1');
        final ref2 = repo.lookupReference('refs/tags/v0.2');

        expect(ref1.target.sha, '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8');
        expect(ref2.target.sha, 'f0fdbf506397e9f58c59b88dfdd72778ec06cc0c');
        expect(repo.references.length, 5);

        repo.renameReference(
          oldName: 'refs/tags/v0.1',
          newName: 'refs/tags/v0.2',
          force: true,
        );

        final updatedRef1 = repo.lookupReference('refs/tags/v0.2');
        expect(
          updatedRef1.target.sha,
          '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
        );
        expect(repo.references, isNot(contains('refs/tags/v0.1')));
        expect(repo.references.length, 4);

        ref1.free();
        ref2.free();
      });
    });

    test('checks equality', () {
      final ref1 = repo.lookupReference('refs/heads/master');
      final ref2 = repo.lookupReference('refs/heads/master');
      final ref3 = repo.lookupReference('refs/heads/feature');

      expect(ref1 == ref2, true);
      expect(ref1 != ref2, false);
      expect(ref1 == ref3, false);
      expect(ref1 != ref3, true);

      ref1.free();
      ref2.free();
      ref3.free();
    });

    test('successfully peels to non-tag object when no type is provided', () {
      final ref = repo.lookupReference('refs/heads/master');
      final commit = repo.lookupCommit(ref.target);
      final peeled = ref.peel() as Commit;

      expect(peeled.oid, commit.oid);

      peeled.free();
      commit.free();
      ref.free();
    });

    test('successfully peels to object of provided type', () {
      final ref = repo.lookupReference('refs/heads/master');
      final blob = repo.lookupBlob(repo['9c78c21']);
      final blobRef = repo.createReference(
        name: 'refs/tags/blob',
        target: blob.oid,
      );
      final tagRef = repo.lookupReference('refs/tags/v0.2');
      final commit = repo.lookupCommit(ref.target);
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

    test('successfully compresses references', () {
      final packedRefsFile = File('${tmpDir.path}/.git/packed-refs');
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
      final ref = repo.lookupReference('refs/heads/master');
      expect(ref.toString(), contains('Reference{'));
      ref.free();
    });
  });
}
