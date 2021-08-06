import 'dart:io';

import 'package:libgit2dart/src/reflog.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/reference.dart';
import 'package:libgit2dart/src/error.dart';

import 'helpers/util.dart';

void main() {
  const lastCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  group('Reference', () {
    late final Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/ref_testrepo/';

    setUpAll(() async {
      if (await Directory(tmpDir).exists()) {
        await Directory(tmpDir).delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/testrepo/'),
        to: await Directory(tmpDir).create(),
      );
      repo = Repository.open(tmpDir);
    });

    tearDownAll(() async {
      repo.free();
      await Directory(tmpDir).delete(recursive: true);
    });

    group('.createDirect()', () {
      test('successfully creates with Oid as target', () {
        final ref = repo.getReference('refs/heads/master');
        final refFromOid = repo.createReference(
          name: 'refs/tags/from.oid',
          target: ref.target,
        );

        expect(repo.references, contains('refs/tags/from.oid'));

        refFromOid.delete();
        refFromOid.free();
        ref.free();
      });

      test('successfully creates with SHA hash as target', () {
        final refFromHash = repo.createReference(
          name: 'refs/tags/from.hash',
          target: lastCommit,
        );

        expect(repo.references, contains('refs/tags/from.hash'));

        refFromHash.delete();
        refFromHash.free();
      });

      test('successfully creates with short SHA hash as target', () {
        final refFromHash = repo.createReference(
          name: 'refs/tags/from.short.hash',
          target: '78b8bf',
        );

        expect(repo.references, contains('refs/tags/from.short.hash'));

        refFromHash.delete();
        refFromHash.free();
      });

      test('successfully creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = repo.createReference(
          name: 'refs/heads/log.message',
          target: lastCommit,
          logMessage: 'log message',
        );

        final reflog = RefLog(ref);
        final reflogEntry = reflog.entryAt(0);

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer, {'name': 'name', 'email': 'email'});

        reflog.free();
        ref.delete();
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
      });

      test('throws if name is not valid', () {
        expect(
          () => repo.createReference(
            name: 'refs/tags/invalid~',
            target: lastCommit,
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully creates with force flag if name already exists', () {
        final ref = repo.createReference(
          name: 'refs/tags/test',
          target: lastCommit,
        );

        final forceRef = repo.createReference(
          name: 'refs/tags/test',
          target: lastCommit,
          force: true,
        );

        expect(forceRef.target.sha, lastCommit);

        forceRef.delete();
        ref.free();
        forceRef.free();
      });

      test('throws if name already exists', () {
        final ref = repo.createReference(
          name: 'refs/tags/test',
          target: lastCommit,
        );

        expect(
          () => repo.createReference(
            name: 'refs/tags/test',
            target: lastCommit,
          ),
          throwsA(isA<LibGit2Error>()),
        );

        ref.delete();
        ref.free();
      });
    });

    group('.createSymbolic()', () {
      test('successfully creates with valid target', () {
        final ref = repo.createReference(
          name: 'refs/tags/symbolic',
          target: 'refs/heads/master',
        );

        expect(repo.references, contains('refs/tags/symbolic'));
        expect(ref.type, ReferenceType.symbolic);

        ref.delete();
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

        forceRef.delete();
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

        ref.delete();
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

        final reflog = RefLog(ref);
        final reflogEntry = reflog.entryAt(0);

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer, {'name': 'name', 'email': 'email'});

        // set HEAD back to master
        repo
            .createReference(
              name: 'HEAD',
              target: 'refs/heads/master',
              force: true,
            )
            .free();

        reflog.free();
        ref.free();
      });
    });

    test('successfully deletes reference', () {
      final ref = repo.createReference(
        name: 'refs/tags/test',
        target: lastCommit,
      );
      expect(repo.references, contains('refs/tags/test'));

      ref.delete();
      expect(repo.references, isNot(contains('refs/tags/test')));
    });

    test('returns correct type of reference', () {
      expect(repo.head.type, ReferenceType.direct);
      repo.head.free();

      final ref = repo.getReference('HEAD');
      expect(ref.type, ReferenceType.symbolic);
      ref.free();
    });

    test('returns SHA hex of direct reference', () {
      expect(repo.head.target.sha, lastCommit);
      repo.head.free();
    });

    test('returns SHA hex of symbolic reference', () {
      final ref = repo.getReference('HEAD');
      expect(ref.target.sha, lastCommit);
      ref.free();
    });

    test('returns the full name of a reference', () {
      expect(repo.head.name, 'refs/heads/master');
      repo.head.free();
    });

    test('returns a map with all the references of repository', () {
      expect(
        repo.references,
        {
          'refs/heads/feature': '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4',
          'refs/heads/master': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
          'refs/tags/v0.1': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
        },
      );
    });

    test('checks if reflog exists for the reference', () {
      expect(repo.referenceHasLog('refs/heads/master'), true);
      expect(repo.referenceHasLog('refs/tags/v0.1'), false);
    });

    test('checks if reference is a local branch', () {
      final ref = repo.getReference('refs/heads/feature');
      expect(ref.isBranch, true);
      ref.free();
    });

    test('checks if reference is a note', () {
      final ref = repo.getReference('refs/heads/master');
      expect(ref.isNote, false);
      ref.free();
    });

    test('checks if reference is a remote branch', () {
      final ref = repo.createReference(
        name: 'refs/remotes/origin/master',
        target: lastCommit,
      );

      expect(ref.isRemote, true);

      ref.delete();
      ref.free();
    });

    test('checks if reference is a tag', () {
      final ref = repo.getReference('refs/tags/v0.1');
      expect(ref.isTag, true);
      ref.free();
    });

    group('.lookup()', () {
      test('finds a reference with provided name', () {
        final ref = repo.getReference('refs/heads/master');
        expect(ref.target.sha, lastCommit);
        ref.free();
      });

      test('throws when error occured', () {
        expect(
          () => repo.getReference('refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('isValidName()', () {
      test('returns true for valid names', () {
        expect(Reference.isValidName('HEAD'), true);
        expect(Reference.isValidName('refs/heads/master'), true);
        expect(Reference.isValidName('refs/heads/perfectly/valid'), true);
        expect(Reference.isValidName('refs/tags/v1'), true);
        expect(Reference.isValidName('refs/special/ref'), true);
        expect(Reference.isValidName('refs/heads/ünicöde'), true);
        expect(Reference.isValidName('refs/tags/😀'), true);
      });

      test('returns false for invalid names', () {
        expect(Reference.isValidName(''), false);
        expect(Reference.isValidName(' refs/heads/master'), false);
        expect(Reference.isValidName('refs/heads/in..valid'), false);
        expect(Reference.isValidName('refs/heads/invalid~'), false);
        expect(Reference.isValidName('refs/heads/invalid^'), false);
        expect(Reference.isValidName('refs/heads/invalid:'), false);
        expect(Reference.isValidName('refs/heads/invalid\\'), false);
        expect(Reference.isValidName('refs/heads/invalid?'), false);
        expect(Reference.isValidName('refs/heads/invalid['), false);
        expect(Reference.isValidName('refs/heads/invalid*'), false);
        expect(Reference.isValidName('refs/heads/@{no}'), false);
        expect(Reference.isValidName('refs/heads/foo//bar'), false);
      });
    });
  });
}
