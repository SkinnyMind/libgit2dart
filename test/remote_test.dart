import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const remoteName = 'origin';
  const remoteUrl = 'git://github.com/SkinnyMind/libgit2dart.git';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Remote', () {
    test('returns list of remotes', () {
      expect(Remote.list(repo), ['origin']);
    });

    test('lookups remote for provided name', () {
      final remote = Remote.lookup(repo: repo, name: 'origin');

      expect(remote.name, remoteName);
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');
      expect(remote.toString(), contains('Remote{'));
      expect(remote, equals(Remote.lookup(repo: repo, name: 'origin')));
    });

    test('throws when provided name for lookup is not found', () {
      expect(
        () => Remote.lookup(repo: repo, name: 'upstream'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to create remote and name already exists', () {
      expect(
        () => Remote.create(repo: repo, name: 'origin', url: remoteUrl),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates without fetchspec', () {
      final remote = Remote.create(
        repo: repo,
        name: 'upstream',
        url: remoteUrl,
      );

      expect(repo.remotes.length, 2);
      expect(remote.name, 'upstream');
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');
    });

    test('creates with provided fetchspec', () {
      const spec = '+refs/*:refs/*';
      final remote = Remote.create(
        repo: repo,
        name: 'upstream',
        url: remoteUrl,
        fetch: spec,
      );

      expect(repo.remotes.length, 2);
      expect(remote.name, 'upstream');
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');
      expect(remote.fetchRefspecs, [spec]);
    });

    test('throws when trying to create with fetchspec with invalid remote name',
        () {
      expect(
        () => Remote.create(repo: repo, name: '', url: '', fetch: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('deletes remote', () {
      final remote = Remote.create(
        repo: repo,
        name: 'upstream',
        url: remoteUrl,
      );
      expect(repo.remotes.length, 2);

      Remote.delete(repo: repo, name: remote.name);
      expect(repo.remotes.length, 1);
    });

    test('throws when trying to delete non existing remote', () {
      expect(
        () => Remote.delete(repo: repo, name: 'not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('renames remote', () {
      final remote = Remote.lookup(repo: repo, name: remoteName);

      final problems = Remote.rename(
        repo: repo,
        oldName: remoteName,
        newName: 'renamed',
      );
      expect(problems, isEmpty);
      expect(remote.name, isNot('renamed'));

      final renamedRemote = Remote.lookup(repo: repo, name: 'renamed');
      expect(renamedRemote.name, 'renamed');
    });

    test('returns list of non-default refspecs that cannot be renamed', () {
      final remote = Remote.create(
        repo: repo,
        name: 'upstream',
        url: remoteUrl,
        fetch: '+refs/*:refs/*',
      );

      expect(
        Remote.rename(repo: repo, oldName: remote.name, newName: 'renamed'),
        ['+refs/*:refs/*'],
      );
    });

    test('throws when renaming with invalid names', () {
      expect(
        () => Remote.rename(repo: repo, oldName: '', newName: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('sets url', () {
      expect(Remote.lookup(repo: repo, name: remoteName).url, remoteUrl);

      const newUrl = 'git://new/url.git';
      Remote.setUrl(repo: repo, remote: remoteName, url: newUrl);

      expect(Remote.lookup(repo: repo, name: remoteName).url, newUrl);
    });

    test('throws when trying to set invalid url name', () {
      expect(
        () => Remote.setUrl(repo: repo, remote: 'origin', url: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('sets url for pushing', () {
      const newUrl = 'git://new/url.git';
      Remote.setPushUrl(repo: repo, remote: remoteName, url: newUrl);

      expect(Remote.lookup(repo: repo, name: remoteName).pushUrl, newUrl);
    });

    test('throws when trying to set invalid push url name', () {
      expect(
        () => Remote.setPushUrl(repo: repo, remote: 'origin', url: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns refspec', () {
      final remote = Remote.lookup(repo: repo, name: 'origin');
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

      expect(refspec, equals(remote.getRefspec(0)));
    });

    test('throws when trying to transform refspec with invalid reference name',
        () {
      final refspec = Remote.lookup(repo: repo, name: 'origin').getRefspec(0);

      expect(
        () => refspec.transform('invalid/name'),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => refspec.rTransform('invalid/name'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds fetch refspec', () {
      Remote.addFetch(
        repo: repo,
        remote: 'origin',
        refspec: '+refs/test/*:refs/test/remotes/*',
      );
      final remote = Remote.lookup(repo: repo, name: 'origin');
      expect(remote.fetchRefspecs.length, 2);
      expect(
        remote.fetchRefspecs,
        [
          '+refs/heads/*:refs/remotes/origin/*',
          '+refs/test/*:refs/test/remotes/*',
        ],
      );
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

    test('adds push refspec', () {
      Remote.addPush(
        repo: repo,
        remote: 'origin',
        refspec: '+refs/test/*:refs/test/remotes/*',
      );
      final remote = Remote.lookup(repo: repo, name: 'origin');
      expect(remote.pushRefspecs.length, 1);
      expect(remote.pushRefspecs, ['+refs/test/*:refs/test/remotes/*']);
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

    test("returns remote repo's reference list", () {
      Remote.setUrl(
        repo: repo,
        remote: 'libgit2',
        url: 'https://github.com/libgit2/TestGitRepository',
      );
      final remote = Remote.lookup(repo: repo, name: 'libgit2');

      final refs = remote.ls();
      expect(refs.first.isLocal, false);
      expect(refs.first.localId, null);
      expect(refs.first.name, 'HEAD');
      expect(refs.first.symRef, 'refs/heads/master');
      expect((refs.first.oid).sha, '49322bb17d3acc9146f98c97d078513228bbf3c0');
      expect(refs.first.toString(), contains('RemoteReference{'));
      expect(refs.first, remote.ls().first);
    });

    test(
        "throws when trying to get remote repo's reference list with "
        "invalid url", () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'invalid');
      final remote = Remote.lookup(repo: repo, name: 'libgit2');

      expect(() => remote.ls(), throwsA(isA<LibGit2Error>()));
    });

    test(
      tags: 'remote_fetch',
      'fetches data',
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
        final remote = Remote.lookup(repo: repo, name: 'libgit2');

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
      },
    );

    test(
      tags: 'remote_fetch',
      'fetches data with proxy set to auto',
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
        final remote = Remote.lookup(repo: repo, name: 'libgit2');

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
      },
    );

    test(
      tags: 'remote_fetch',
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
        final remote = Remote.lookup(repo: repo, name: 'libgit2');

        expect(
          () => remote.fetch(
            refspecs: ['+refs/heads/*:refs/remotes/origin/*'],
            proxy: 'https://1.1.1.1',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      },
    );

    test('throws when trying to fetch data with invalid url', () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'https://wrong.url');
      final remote = Remote.lookup(repo: repo, name: 'libgit2');

      expect(
        () => remote.fetch(),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
      tags: 'remote_fetch',
      'fetches data with provided transfer progress callback',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        final remote = Remote.lookup(repo: repo, name: 'libgit2');

        TransferProgress? callbackStats;
        void tp(TransferProgress stats) => callbackStats = stats;

        final stats = remote.fetch(callbacks: Callbacks(transferProgress: tp));

        expect(stats.totalObjects == callbackStats?.totalObjects, true);
        expect(stats.indexedObjects == callbackStats?.indexedObjects, true);
        expect(stats.receivedObjects == callbackStats?.receivedObjects, true);
        expect(stats.localObjects == callbackStats?.localObjects, true);
        expect(stats.totalDeltas == callbackStats?.totalDeltas, true);
        expect(stats.indexedDeltas == callbackStats?.indexedDeltas, true);
        expect(stats.receivedBytes == callbackStats?.receivedBytes, true);
      },
    );

    test(
      tags: 'remote_fetch',
      'fetches data with provided sideband progress callback',
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
        final remote = Remote.lookup(repo: repo, name: 'libgit2');

        final sidebandOutput = StringBuffer();
        void sideband(String message) => sidebandOutput.write(message);

        remote.fetch(callbacks: Callbacks(sidebandProgress: sideband));
        expect(sidebandOutput.toString(), sidebandMessage);
      },
    );

    test(
      tags: 'remote_fetch',
      'fetches data with provided update tips callback',
      () {
        Remote.setUrl(
          repo: repo,
          remote: 'libgit2',
          url: 'https://github.com/libgit2/TestGitRepository',
        );
        final remote = Remote.lookup(repo: repo, name: 'libgit2');
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

        remote.fetch(callbacks: Callbacks(updateTips: updateTips));
        expect(updateTipsOutput, tipsExpected);
      },
    );

    test('pushes with update reference callback', () {
      final originDir = Directory.systemTemp.createTempSync('origin');

      copyRepo(
        from: Directory(p.join('test', 'assets', 'empty_bare.git')),
        to: originDir,
      );
      final originRepo = Repository.open(originDir.path);

      Remote.create(repo: repo, name: 'local', url: originDir.path);
      final remote = Remote.lookup(repo: repo, name: 'local');

      final updateRefOutput = <String, String>{};
      void updateRef(String refname, String message) {
        updateRefOutput[refname] = message;
      }

      remote.push(
        refspecs: ['refs/heads/master'],
        callbacks: Callbacks(pushUpdateReference: updateRef),
      );
      expect(
        Commit.lookup(repo: originRepo, oid: originRepo.head.target).oid.sha,
        '821ed6e80627b8769d170a293862f9fc60825226',
      );
      expect(updateRefOutput, {'refs/heads/master': ''});

      if (Platform.isLinux || Platform.isMacOS) {
        originDir.deleteSync(recursive: true);
      }
    });

    test('throws when trying to push to invalid url', () {
      Remote.setUrl(repo: repo, remote: 'libgit2', url: 'https://wrong.url');
      final remote = Remote.lookup(repo: repo, name: 'libgit2');

      expect(
        () => remote.push(refspecs: ['refs/heads/master']),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final remote = Remote.lookup(repo: repo, name: 'origin');
      expect(() => remote.free(), returnsNormally);
    });
  });

  group('RemoteCallback', () {
    test('initializes and returns values', () {
      const remoteCallback = RemoteCallback(
        name: 'name',
        url: 'url',
        fetch: 'fetchRefspec',
      );

      expect(remoteCallback, isA<RemoteCallback>());
      expect(remoteCallback.name, 'name');
      expect(remoteCallback.url, 'url');
      expect(remoteCallback.fetch, 'fetchRefspec');
    });
  });
}
