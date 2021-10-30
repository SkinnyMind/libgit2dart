import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const remoteName = 'origin';
  const remoteUrl = 'git://github.com/SkinnyMind/libgit2dart.git';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Remote', () {
    test('returns list of remotes', () {
      expect(repo.remotes, ['origin']);
    });

    test('successfully looks up remote for provided name', () {
      final remote = repo.lookupRemote('origin');

      expect(remote.name, remoteName);
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');
      expect(remote.toString(), contains('Remote{'));

      remote.free();
    });

    test('throws when provided name for lookup is not found', () {
      expect(() => repo.lookupRemote('upstream'), throwsA(isA<LibGit2Error>()));
    });

    test('successfully creates without fetchspec', () {
      final remote = repo.createRemote(name: 'upstream', url: remoteUrl);

      expect(repo.remotes.length, 2);
      expect(remote.name, 'upstream');
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');

      remote.free();
    });

    test('successfully creates with provided fetchspec', () {
      const spec = '+refs/*:refs/*';
      final remote = repo.createRemote(
        name: 'upstream',
        url: remoteUrl,
        fetch: spec,
      );

      expect(repo.remotes.length, 2);
      expect(remote.name, 'upstream');
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');
      expect(remote.fetchRefspecs, [spec]);

      remote.free();
    });

    test('throws when trying to create with fetchspec with invalid remote name',
        () {
      expect(
        () => repo.createRemote(
          name: '',
          url: '',
          fetch: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully deletes', () {
      final remote = repo.createRemote(name: 'upstream', url: remoteUrl);
      expect(repo.remotes.length, 2);

      repo.deleteRemote(remote.name);
      expect(repo.remotes.length, 1);

      remote.free();
    });

    test('throws when trying to delete non existing remote', () {
      expect(
        () => repo.deleteRemote('not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully renames', () {
      final remote = repo.lookupRemote(remoteName);

      final problems = repo.renameRemote(oldName: remoteName, newName: 'new');
      expect(problems, isEmpty);
      expect(remote.name, isNot('new'));

      final newRemote = repo.lookupRemote('new');
      expect(newRemote.name, 'new');

      newRemote.free();
      remote.free();
    });

    test('returns list of non-default refspecs that cannot be renamed', () {
      final remote = repo.createRemote(
        name: 'upstream',
        url: remoteUrl,
        fetch: '+refs/*:refs/*',
      );

      expect(
        repo.renameRemote(oldName: remote.name, newName: 'renamed'),
        ['+refs/*:refs/*'],
      );

      remote.free();
    });

    test('throws when renaming with invalid names', () {
      expect(
        () => repo.renameRemote(oldName: '', newName: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully sets url', () {
      final remote = repo.lookupRemote(remoteName);
      expect(remote.url, remoteUrl);

      const newUrl = 'git://new/url.git';
      Remote.setUrl(repo: repo, remote: remoteName, url: newUrl);

      final newRemote = repo.lookupRemote(remoteName);
      expect(newRemote.url, newUrl);

      newRemote.free();
      remote.free();
    });

    test('throws when trying to set invalid url name', () {
      expect(
        () => Remote.setUrl(repo: repo, remote: 'origin', url: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully sets url for pushing', () {
      const newUrl = 'git://new/url.git';
      Remote.setPushUrl(repo: repo, remote: remoteName, url: newUrl);

      final remote = repo.lookupRemote(remoteName);
      expect(remote.pushUrl, newUrl);

      remote.free();
    });

    test('throws when trying to set invalid push url name', () {
      expect(
        () => Remote.setPushUrl(repo: repo, remote: 'origin', url: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns refspec', () {
      final remote = repo.lookupRemote('origin');
      expect(remote.refspecCount, 1);

      final refspec = remote.getRefspec(0);
      expect(refspec.source, 'refs/heads/*');
      expect(refspec.destination, 'refs/remotes/origin/*');
      expect(refspec.force, true);
      expect(refspec.direction, GitDirection.fetch);
      expect(refspec.string, '+refs/heads/*:refs/remotes/origin/*');
      expect(refspec.toString(), contains('Refspec{'));
      expect(remote.fetchRefspecs, ['+refs/heads/*:refs/remotes/origin/*']);

      expect(refspec.matchesSource('refs/heads/master'), true);
      expect(refspec.matchesDestination('refs/remotes/origin/master'), true);

      expect(
        refspec.transform('refs/heads/master'),
        'refs/remotes/origin/master',
      );
      expect(
        refspec.rTransform('refs/remotes/origin/master'),
        'refs/heads/master',
      );

      remote.free();
    });

    test('throws when trying to transform refspec with invalid reference name',
        () {
      final remote = repo.lookupRemote('origin');
      final refspec = remote.getRefspec(0);

      expect(
        () => refspec.transform('invalid/name'),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => refspec.rTransform('invalid/name'),
        throwsA(isA<LibGit2Error>()),
      );

      remote.free();
    });

    test('successfully adds fetch refspec', () {
      Remote.addFetch(
        repo: repo,
        remote: 'origin',
        refspec: '+refs/test/*:refs/test/remotes/*',
      );
      final remote = repo.lookupRemote('origin');
      expect(remote.fetchRefspecs.length, 2);
      expect(
        remote.fetchRefspecs,
        [
          '+refs/heads/*:refs/remotes/origin/*',
          '+refs/test/*:refs/test/remotes/*',
        ],
      );

      remote.free();
    });

    test('throws when trying to add fetch refspec for invalid remote name', () {
      expect(
        () => Remote.addFetch(
          repo: repo,
          remote: '',
          refspec: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully adds push refspec', () {
      Remote.addPush(
        repo: repo,
        remote: 'origin',
        refspec: '+refs/test/*:refs/test/remotes/*',
      );
      final remote = repo.lookupRemote('origin');
      expect(remote.pushRefspecs.length, 1);
      expect(remote.pushRefspecs, ['+refs/test/*:refs/test/remotes/*']);

      remote.free();
    });

    test('throws when trying to add push refspec for invalid remote name', () {
      expect(
        () => Remote.addPush(
          repo: repo,
          remote: '',
          refspec: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test("successfully returns remote repo's reference list", () {
      Remote.setUrl(
        repo: repo,
        remote: 'libgit2',
        url: 'https://github.com/libgit2/TestGitRepository',
      );
      final remote = repo.lookupRemote('libgit2');

      final refs = remote.ls();
      expect(refs.first['local'], false);
      expect(refs.first['loid'], null);
      expect(refs.first['name'], 'HEAD');
      expect(refs.first['symref'], 'refs/heads/master');
      expect(
        (refs.first['oid']! as Oid).sha,
        '49322bb17d3acc9146f98c97d078513228bbf3c0',
      );

      remote.free();
    });

    test(
        "throws when trying to get remote repo's reference list with "
        "invalid url", () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'invalid');
      final remote = repo.lookupRemote('libgit2');

      expect(() => remote.ls(), throwsA(isA<LibGit2Error>()));

      remote.free();
    });

    test(
      'successfully fetches data',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        Remote.addFetch(
          repo: repo,
          remote: 'libgit2',
          refspec: '+refs/heads/*:refs/remotes/origin/*',
        );
        final remote = repo.lookupRemote('libgit2');

        final stats = remote.fetch(
          refspecs: ['+refs/heads/*:refs/remotes/origin/*'],
        );

        expect(stats.totalObjects, 69);
        expect(stats.indexedObjects, 69);
        expect(stats.receivedObjects, 69);
        expect(stats.localObjects, 0);
        expect(stats.totalDeltas, 3);
        expect(stats.indexedDeltas, 3);
        expect(stats.receivedBytes, 0);
        expect(stats.toString(), contains('TransferProgress{'));

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test(
      'successfully fetches data with proxy set to auto',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        Remote.addFetch(
          repo: repo,
          remote: 'libgit2',
          refspec: '+refs/heads/*:refs/remotes/origin/*',
        );
        final remote = repo.lookupRemote('libgit2');

        final stats = remote.fetch(
          refspecs: ['+refs/heads/*:refs/remotes/origin/*'],
          proxy: 'auto',
        );

        expect(stats.totalObjects, 69);
        expect(stats.indexedObjects, 69);
        expect(stats.receivedObjects, 69);
        expect(stats.localObjects, 0);
        expect(stats.totalDeltas, 3);
        expect(stats.indexedDeltas, 3);
        expect(stats.receivedBytes, 0);
        expect(stats.toString(), contains('TransferProgress{'));

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test(
      'uses specified proxy for fetch',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        Remote.addFetch(
          repo: repo,
          remote: 'libgit2',
          refspec: '+refs/heads/*:refs/remotes/origin/*',
        );
        final remote = repo.lookupRemote('libgit2');

        expect(
          () => remote.fetch(
            refspecs: ['+refs/heads/*:refs/remotes/origin/*'],
            proxy: 'https://1.1.1.1',
          ),
          throwsA(isA<LibGit2Error>()),
        );

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test('throws when trying to fetch data with invalid url', () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'https://wrong.url');
      final remote = repo.lookupRemote('libgit2');

      expect(
        () => remote.fetch(),
        throwsA(isA<LibGit2Error>()),
      );

      remote.free();
    });

    test(
      'successfully fetches data with provided transfer progress callback',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        final remote = repo.lookupRemote('libgit2');

        TransferProgress? callbackStats;
        void tp(TransferProgress stats) => callbackStats = stats;
        final callbacks = Callbacks(transferProgress: tp);

        final stats = remote.fetch(callbacks: callbacks);

        expect(stats.totalObjects == callbackStats?.totalObjects, true);
        expect(stats.indexedObjects == callbackStats?.indexedObjects, true);
        expect(stats.receivedObjects == callbackStats?.receivedObjects, true);
        expect(stats.localObjects == callbackStats?.localObjects, true);
        expect(stats.totalDeltas == callbackStats?.totalDeltas, true);
        expect(stats.indexedDeltas == callbackStats?.indexedDeltas, true);
        expect(stats.receivedBytes == callbackStats?.receivedBytes, true);

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test(
      'successfully fetches data with provided sideband progress callback',
      () {
        const sidebandMessage = """
Enumerating objects: 69, done.
Counting objects: 100% (1/1)\rCounting objects: 100% (1/1), done.
Total 69 (delta 0), reused 1 (delta 0), pack-reused 68
""";
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        final remote = repo.lookupRemote('libgit2');

        final sidebandOutput = StringBuffer();
        void sideband(String message) {
          sidebandOutput.write(message);
        }

        final callbacks = Callbacks(sidebandProgress: sideband);

        remote.fetch(callbacks: callbacks);
        expect(sidebandOutput.toString(), sidebandMessage);

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test(
      'successfully fetches data with provided update tips callback',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        final remote = repo.lookupRemote('libgit2');
        final tipsExpected = [
          {
            'refname': 'refs/tags/annotated_tag',
            'oldSha': '0' * 40,
            'newSha': 'd96c4e80345534eccee5ac7b07fc7603b56124cb',
          },
          {
            'refname': 'refs/tags/blob',
            'oldSha': '0' * 40,
            'newSha': '55a1a760df4b86a02094a904dfa511deb5655905'
          },
          {
            'refname': 'refs/tags/commit_tree',
            'oldSha': '0' * 40,
            'newSha': '8f50ba15d49353813cc6e20298002c0d17b0a9ee',
          },
        ];

        final updateTipsOutput = <Map<String, String>>[];
        void updateTips(String refname, Oid oldOid, Oid newOid) {
          updateTipsOutput.add({
            'refname': refname,
            'oldSha': oldOid.sha,
            'newSha': newOid.sha,
          });
        }

        final callbacks = Callbacks(updateTips: updateTips);

        remote.fetch(callbacks: callbacks);
        expect(updateTipsOutput, tipsExpected);

        remote.free();
      },
      tags: 'remote_fetch',
    );

    test('successfully pushes with update reference callback', () {
      final originDir =
          Directory('${Directory.systemTemp.path}/origin_testrepo');

      if (originDir.existsSync()) {
        originDir.deleteSync(recursive: true);
      }
      originDir.createSync();
      copyRepo(
        from: Directory('test/assets/empty_bare.git/'),
        to: originDir,
      );
      final originRepo = Repository.open(originDir.path);

      repo.createRemote(name: 'local', url: originDir.path);
      final remote = repo.lookupRemote('local');

      final updateRefOutput = <String, String>{};
      void updateRef(String refname, String message) {
        updateRefOutput[refname] = message;
      }

      final callbacks = Callbacks(pushUpdateReference: updateRef);

      remote.push(refspecs: ['refs/heads/master'], callbacks: callbacks);
      expect(
        originRepo.lookupCommit(originRepo.head.target).oid.sha,
        '821ed6e80627b8769d170a293862f9fc60825226',
      );
      expect(updateRefOutput, {'refs/heads/master': ''});

      remote.free();
      originRepo.free();
      originDir.delete(recursive: true);
    });

    test('throws when trying to push to invalid url', () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'https://wrong.url');
      final remote = repo.lookupRemote('libgit2');

      expect(
        () => remote.push(refspecs: ['refs/heads/master']),
        throwsA(isA<LibGit2Error>()),
      );

      remote.free();
    });
  });
}
