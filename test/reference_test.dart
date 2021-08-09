import 'dart:io';

import 'package:libgit2dart/src/reflog.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/reference.dart';
import 'package:libgit2dart/src/error.dart';

import 'helpers/util.dart';

void main() {
  const lastCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const newCommit = 'c68ff54aabf660fcdd9a2838d401583fe31249e3';

  group('Reference', () {
    late Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/ref_testrepo/';

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

    group('.createDirect()', () {
      test('successfully creates with Oid as target', () {
        final ref = Reference.get(repo, 'refs/heads/master');
        final refFromOid = Reference.create(
          repository: repo,
          name: 'refs/tags/from.oid',
          target: ref.target,
        );

        expect(Reference.list(repo), contains('refs/tags/from.oid'));

        refFromOid.free();
        ref.free();
      });

      test('successfully creates with SHA hash as target', () {
        final refFromHash = Reference.create(
          repository: repo,
          name: 'refs/tags/from.hash',
          target: lastCommit,
        );

        expect(Reference.list(repo), contains('refs/tags/from.hash'));

        refFromHash.free();
      });

      test('successfully creates with short SHA hash as target', () {
        final refFromHash = Reference.create(
          repository: repo,
          name: 'refs/tags/from.short.hash',
          target: '78b8bf',
        );

        expect(Reference.list(repo), contains('refs/tags/from.short.hash'));

        refFromHash.free();
      });

      test('successfully creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = Reference.create(
          repository: repo,
          name: 'refs/heads/log.message',
          target: lastCommit,
          logMessage: 'log message',
        );

        final reflog = RefLog(ref);
        final reflogEntry = reflog.entryAt(0);

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer['name'], 'name');
        expect(reflogEntry.committer['email'], 'email');

        reflog.free();
        ref.free();
      });

      test('throws if target is not valid', () {
        expect(
          () => Reference.create(
            repository: repo,
            name: 'refs/tags/invalid',
            target: '78b',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws if name is not valid', () {
        expect(
          () => Reference.create(
            repository: repo,
            name: 'refs/tags/invalid~',
            target: lastCommit,
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully creates with force flag if name already exists', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/test',
          target: lastCommit,
        );

        final forceRef = Reference.create(
          repository: repo,
          name: 'refs/tags/test',
          target: lastCommit,
          force: true,
        );

        expect(forceRef.target.sha, lastCommit);

        ref.free();
        forceRef.free();
      });

      test('throws if name already exists', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/test',
          target: lastCommit,
        );

        expect(
          () => Reference.create(
            repository: repo,
            name: 'refs/tags/test',
            target: lastCommit,
          ),
          throwsA(isA<LibGit2Error>()),
        );

        ref.free();
      });
    });

    group('.createSymbolic()', () {
      test('successfully creates with valid target', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/symbolic',
          target: 'refs/heads/master',
        );

        expect(Reference.list(repo), contains('refs/tags/symbolic'));
        expect(ref.type, ReferenceType.symbolic);

        ref.free();
      });

      test('successfully creates with force flag if name already exists', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/test',
          target: 'refs/heads/master',
        );

        final forceRef = Reference.create(
          repository: repo,
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
          repository: repo,
          name: 'refs/tags/exists',
          target: 'refs/heads/master',
        );

        expect(
          () => Reference.create(
            repository: repo,
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
            repository: repo,
            name: 'refs/tags/invalid~',
            target: 'refs/heads/master',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully creates with log message', () {
        repo.setIdentity(name: 'name', email: 'email');
        final ref = Reference.create(
          repository: repo,
          name: 'HEAD',
          target: 'refs/heads/feature',
          force: true,
          logMessage: 'log message',
        );

        final reflog = RefLog(ref);
        final reflogEntry = reflog.entryAt(0);

        expect(reflogEntry.message, 'log message');
        expect(reflogEntry.committer['name'], 'name');
        expect(reflogEntry.committer['email'], 'email');

        reflog.free();
        ref.free();
      });
    });

    test('successfully deletes reference', () {
      final ref = Reference.create(
        repository: repo,
        name: 'refs/tags/test',
        target: lastCommit,
      );
      expect(Reference.list(repo), contains('refs/tags/test'));

      ref.delete();
      expect(Reference.list(repo), isNot(contains('refs/tags/test')));
      ref.free();
    });

    test('returns correct type of reference', () {
      final head = repo.head;
      expect(head.type, ReferenceType.direct);
      head.free();

      final ref = Reference.get(repo, 'HEAD');
      expect(ref.type, ReferenceType.symbolic);
      ref.free();
    });

    test('returns SHA hex of direct reference', () {
      final head = repo.head;
      expect(head.target.sha, lastCommit);
      head.free();
    });

    test('returns SHA hex of symbolic reference', () {
      final ref = Reference.get(repo, 'HEAD');
      expect(ref.target.sha, lastCommit);
      ref.free();
    });

    test('returns the full name', () {
      final head = repo.head;
      expect(head.name, 'refs/heads/master');
      head.free();
    });

    test('returns the short name', () {
      final ref = Reference.create(
        repository: repo,
        name: 'refs/remotes/origin/master',
        target: lastCommit,
      );

      final head = repo.head;

      expect(head.shorthand, 'master');
      expect(ref.shorthand, 'origin/master');

      head.free();
      ref.free();
    });

    test('returns a map with all the references of repository', () {
      expect(
        Reference.list(repo),
        ['refs/heads/feature', 'refs/heads/master', 'refs/tags/v0.1'],
      );
    });

    test('checks if reflog exists for the reference', () {
      expect(Reference.hasLog(repo, 'refs/heads/master'), true);
      expect(Reference.hasLog(repo, 'refs/tags/v0.1'), false);
    });

    test('checks if reference is a local branch', () {
      final ref = Reference.get(repo, 'refs/heads/feature');
      expect(ref.isBranch, true);
      ref.free();
    });

    test('checks if reference is a note', () {
      final ref = Reference.get(repo, 'refs/heads/master');
      expect(ref.isNote, false);
      ref.free();
    });

    test('checks if reference is a remote branch', () {
      final ref = Reference.create(
        repository: repo,
        name: 'refs/remotes/origin/master',
        target: lastCommit,
      );

      expect(ref.isRemote, true);

      ref.free();
    });

    test('checks if reference is a tag', () {
      final ref = Reference.get(repo, 'refs/tags/v0.1');
      expect(ref.isTag, true);
      ref.free();
    });

    group('.lookup()', () {
      test('finds a reference with provided name', () {
        final ref = Reference.get(repo, 'refs/heads/master');
        expect(ref.target.sha, lastCommit);
        ref.free();
      });

      test('throws when error occured', () {
        expect(
          () => Reference.get(repo, 'refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('.lookupDWIM()', () {
      test('finds a reference with provided name', () {
        final remoteRef = Reference.create(
          repository: repo,
          name: 'refs/remotes/origin/master',
          target: lastCommit,
        );
        expect(remoteRef.shorthand, 'origin/master');

        final tagRef = Reference.create(
          repository: repo,
          name: 'refs/tags/v1',
          target: lastCommit,
        );
        expect(tagRef.shorthand, 'v1');

        var ref = Reference.getDWIM(repo, 'refs/heads/master');
        expect(ref.name, 'refs/heads/master');

        ref = Reference.getDWIM(repo, 'master');
        expect(ref.name, 'refs/heads/master');

        ref = Reference.getDWIM(repo, 'origin/master');
        expect(ref.name, 'refs/remotes/origin/master');

        ref = Reference.getDWIM(repo, 'v1');
        expect(ref.name, 'refs/tags/v1');

        remoteRef.free();
        tagRef.free();
        ref.free();
      });

      test('throws when error occured', () {
        expect(
          () => Reference.getDWIM(repo, 'refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns log for reference', () {
      final ref = Reference.get(repo, 'refs/heads/master');
      expect(ref.log.last.message, 'commit (initial): init');
      ref.free();
    });

    group('.setTarget()', () {
      test('successfully sets target with SHA hex', () {
        final ref = Reference.get(repo, 'refs/heads/master');
        ref.setTarget(newCommit);
        expect(ref.target.sha, newCommit);

        ref.free();
      });

      test('successfully sets target with short SHA hex', () {
        final ref = Reference.get(repo, 'refs/heads/master');
        ref.setTarget(newCommit.substring(0, 5));
        expect(ref.target.sha, newCommit);

        ref.free();
      });

      test('successfully sets symbolic target', () {
        final ref = Reference.get(repo, 'HEAD');
        expect(ref.target.sha, lastCommit);

        ref.setTarget('refs/heads/feature');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');

        ref.free();
      });

      test('successfully sets target with log message', () {
        final ref = Reference.get(repo, 'HEAD');
        expect(ref.target.sha, lastCommit);

        repo.setIdentity(name: 'name', email: 'email');
        ref.setTarget('refs/heads/feature', 'log message');
        expect(ref.target.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
        expect(ref.log.first.message, 'log message');
        expect(ref.log.first.committer['name'], 'name');
        expect(ref.log.first.committer['email'], 'email');

        ref.free();
      });

      test('throws on invalid target', () {
        final ref = Reference.get(repo, 'HEAD');
        expect(
          () => ref.setTarget('refs/heads/invalid~'),
          throwsA(isA<LibGit2Error>()),
        );

        ref.free();
      });
    });

    group('.rename()', () {
      test('successfully renames reference', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/v1',
          target: lastCommit,
        );
        expect(ref.name, 'refs/tags/v1');

        ref.rename('refs/tags/v2');
        expect(ref.name, 'refs/tags/v2');

        ref.free();
      });

      test('throws on invalid name', () {
        final ref = Reference.create(
          repository: repo,
          name: 'refs/tags/v1',
          target: lastCommit,
        );

        expect(
          () => ref.rename('refs/tags/invalid~'),
          throwsA(isA<LibGit2Error>()),
        );

        ref.free();
      });

      test('throws if name already exists', () {
        final ref1 = Reference.create(
          repository: repo,
          name: 'refs/tags/v1',
          target: lastCommit,
        );

        final ref2 = Reference.create(
          repository: repo,
          name: 'refs/tags/v2',
          target: lastCommit,
        );

        expect(
          () => ref1.rename('refs/tags/v2'),
          throwsA(isA<LibGit2Error>()),
        );

        ref1.free();
        ref2.free();
      });

      test('successfully renames with force flag set to true', () {
        final ref1 = Reference.create(
          repository: repo,
          name: 'refs/tags/v1',
          target: lastCommit,
        );

        final ref2 = Reference.create(
          repository: repo,
          name: 'refs/tags/v2',
          target: newCommit,
        );

        expect(ref2.target.sha, newCommit);

        ref1.rename('refs/tags/v2', force: true);
        expect(ref1.name, 'refs/tags/v2');

        ref1.free();
        ref2.free();
      });
    });

    test('checks equality', () {
      final ref1 = Reference.get(repo, 'refs/heads/master');
      final ref2 = Reference.get(repo, 'refs/heads/master');
      final ref3 = Reference.get(repo, 'refs/heads/feature');

      expect(ref1 == ref2, true);
      expect(ref1 != ref2, false);
      expect(ref1 == ref3, false);
      expect(ref1 != ref3, true);

      ref1.free();
      ref2.free();
      ref3.free();
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
