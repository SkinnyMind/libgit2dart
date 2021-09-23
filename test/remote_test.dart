import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const remoteName = 'origin';
  const remoteUrl = 'git://github.com/SkinnyMind/libgit2dart.git';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Remote', () {
    test('returns list of remotes', () {
      expect(repo.remotes.list, ['origin']);
    });

    test('successfully looks up remote for provided name', () {
      final remote = repo.remotes['origin'];

      expect(remote.name, remoteName);
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');

      remote.free();
    });

    test('throws when provided name for lookup is not found', () {
      expect(() => repo.remotes['upstream'], throwsA(isA<LibGit2Error>()));
    });

    test('successfully creates without fetchspec', () {
      final remote = repo.remotes.create(name: 'upstream', url: remoteUrl);

      expect(repo.remotes.length, 2);
      expect(remote.name, 'upstream');
      expect(remote.url, remoteUrl);
      expect(remote.pushUrl, '');

      remote.free();
    });

    test('successfully creates with provided fetchspec', () {
      const spec = '+refs/*:refs/*';
      final remote = repo.remotes.create(
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

    test('successfully deletes', () {
      final remote = repo.remotes.create(name: 'upstream', url: remoteUrl);
      expect(repo.remotes.length, 2);

      repo.remotes.delete(remote.name);
      expect(repo.remotes.length, 1);

      remote.free();
    });

    test('successfully renames', () {
      final remote = repo.remotes[remoteName];

      final problems = repo.remotes.rename(remoteName, 'new');
      expect(problems, isEmpty);
      expect(remote.name, isNot('new'));

      final newRemote = repo.remotes['new'];
      expect(newRemote.name, 'new');

      newRemote.free();
      remote.free();
    });

    test('throws when renaming with invalid names', () {
      expect(() => repo.remotes.rename('', ''), throwsA(isA<LibGit2Error>()));
    });

    test('successfully sets url', () {
      final remote = repo.remotes[remoteName];
      expect(remote.url, remoteUrl);

      const newUrl = 'git://new/url.git';
      repo.remotes.setUrl(remoteName, newUrl);

      final newRemote = repo.remotes[remoteName];
      expect(newRemote.url, newUrl);

      newRemote.free();
      remote.free();
    });

    test('throws when trying to set invalid url name', () {
      expect(
        () => repo.remotes.setUrl('origin', ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully sets url for pushing', () {
      const newUrl = 'git://new/url.git';
      repo.remotes.setPushUrl(remoteName, newUrl);

      final remote = repo.remotes[remoteName];
      expect(remote.pushUrl, newUrl);

      remote.free();
    });

    test('throws when trying to set invalid push url name', () {
      expect(
        () => repo.remotes.setPushUrl('origin', ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns refspec', () {
      final remote = repo.remotes['origin'];
      expect(remote.refspecCount, 1);

      final refspec = remote.getRefspec(0);
      expect(refspec.source, 'refs/heads/*');
      expect(refspec.destination, 'refs/remotes/origin/*');
      expect(refspec.force, true);
      expect(refspec.string, '+refs/heads/*:refs/remotes/origin/*');
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

    test('successfully adds fetch refspec', () {
      repo.remotes.addFetch('origin', '+refs/test/*:refs/test/remotes/*');
      final remote = repo.remotes['origin'];
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

    test('successfully adds push refspec', () {
      repo.remotes.addPush('origin', '+refs/test/*:refs/test/remotes/*');
      final remote = repo.remotes['origin'];
      expect(remote.pushRefspecs.length, 1);
      expect(remote.pushRefspecs, ['+refs/test/*:refs/test/remotes/*']);

      remote.free();
    });

    test('successfully returns remote repo\'s reference list', () {
      repo.remotes.setUrl(
        'libgit2',
        'https://github.com/libgit2/TestGitRepository',
      );
      final remote = repo.remotes['libgit2'];

      final refs = remote.ls();
      expect(refs.first['local'], false);
      expect(refs.first['loid'], null);
      expect(refs.first['name'], 'HEAD');
      expect(refs.first['symref'], 'refs/heads/master');
      expect(
        (refs.first['oid'] as Oid).sha,
        '49322bb17d3acc9146f98c97d078513228bbf3c0',
      );

      remote.free();
    });

    test('successfully fetches data', () async {
      repo.remotes.setUrl(
        'libgit2',
        'https://github.com/libgit2/TestGitRepository',
      );
      final remote = repo.remotes['libgit2'];

      final stats = remote.fetch();

      expect(stats.totalObjects, 69);
      expect(stats.indexedObjects, 69);
      expect(stats.receivedObjects, 69);
      expect(stats.localObjects, 0);
      expect(stats.totalDeltas, 3);
      expect(stats.indexedDeltas, 3);
      expect(stats.receivedBytes, 0);

      remote.free();
    });

    test('successfully pushes', () async {
      final originDir =
          Directory('${Directory.systemTemp.path}/origin_testrepo');

      if (await originDir.exists()) {
        await originDir.delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/empty_bare.git/'),
        to: await originDir.create(),
      );
      final originRepo = Repository.open(originDir.path);

      repo.remotes.create(name: 'local', url: originDir.path);
      final remote = repo.remotes['local'];

      remote.push(['refs/heads/master']);
      expect(
        (originRepo[originRepo.head.target.sha] as Commit).id.sha,
        '821ed6e80627b8769d170a293862f9fc60825226',
      );

      remote.free();
      originRepo.free();
      originDir.delete(recursive: true);
    });
  });
}
