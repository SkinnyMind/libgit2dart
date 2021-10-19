import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final cloneDir = Directory('${Directory.systemTemp.path}/credentials_cloned');

  setUp(() {
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
  });

  tearDown(() {
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
  });
  group('Credentials', () {
    test('successfully initializes username credentials', () {
      final credentials = const Username('user');

      expect(credentials, isA<Credentials>());
      expect(credentials.username, 'user');
      expect(credentials.credentialType, GitCredential.username);
      expect(credentials.toString(), contains('Username{'));
    });

    test('successfully initializes username/password credentials', () {
      final credentials = const UserPass(
        username: 'user',
        password: 'password',
      );

      expect(credentials, isA<Credentials>());
      expect(credentials.username, 'user');
      expect(credentials.password, 'password');
      expect(credentials.credentialType, GitCredential.userPassPlainText);
      expect(credentials.toString(), contains('UserPass{'));
    });

    test('successfully initializes keypair credentials', () {
      final credentials = const Keypair(
        username: 'user',
        pubKey: 'id_rsa.pub',
        privateKey: 'id_rsa',
        passPhrase: 'passphrase',
      );

      expect(credentials, isA<Credentials>());
      expect(credentials.username, 'user');
      expect(credentials.pubKey, 'id_rsa.pub');
      expect(credentials.privateKey, 'id_rsa');
      expect(credentials.passPhrase, 'passphrase');
      expect(credentials.credentialType, GitCredential.sshKey);
      expect(credentials.toString(), contains('Keypair{'));
    });

    test('successfully initializes keypair from memory credentials', () {
      final credentials = const KeypairFromMemory(
        username: 'user',
        pubKey: 'pubkey data',
        privateKey: 'private key data',
        passPhrase: 'passphrase',
      );

      expect(credentials, isA<Credentials>());
      expect(credentials.username, 'user');
      expect(credentials.pubKey, 'pubkey data');
      expect(credentials.privateKey, 'private key data');
      expect(credentials.passPhrase, 'passphrase');
      expect(credentials.credentialType, GitCredential.sshMemory);
      expect(credentials.toString(), contains('KeypairFromMemory{'));
    });

    test('successfully initializes keypair from agent credentials', () {
      final credentials = const KeypairFromAgent('user');

      expect(credentials, isA<Credentials>());
      expect(credentials.username, 'user');
      expect(credentials.credentialType, GitCredential.sshKey);
      expect(credentials.toString(), contains('KeypairFromAgent{'));
    });

    test('sucessfully clones repository with provided username', () {
      final callbacks = const Callbacks(credentials: Username('git'));

      final repo = Repository.clone(
        url: 'https://git@github.com/libgit2/TestGitRepository',
        localPath: cloneDir.path,
        callbacks: callbacks,
      );

      expect(repo.isEmpty, false);

      repo.free();
    });

    test('sucessfully clones repository with provided keypair', () {
      final keypair = const Keypair(
        username: 'git',
        pubKey: 'test/assets/keys/id_rsa.pub',
        privateKey: 'test/assets/keys/id_rsa',
        passPhrase: 'empty',
      );
      final callbacks = Callbacks(credentials: keypair);

      final repo = Repository.clone(
        url: 'ssh://git@github.com/libgit2/TestGitRepository',
        localPath: cloneDir.path,
        callbacks: callbacks,
      );

      expect(repo.isEmpty, false);

      repo.free();
    });

    test('throws when no credentials is provided', () {
      expect(
        () => Repository.clone(
          url: 'ssh://git@github.com/libgit2/TestGitRepository',
          localPath: cloneDir.path,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when provided keypair is invalid', () {
      final keypair = const Keypair(
        username: 'git',
        pubKey: 'invalid.pub',
        privateKey: 'invalid',
        passPhrase: 'invalid',
      );
      final callbacks = Callbacks(credentials: keypair);

      expect(
        () => Repository.clone(
          url: 'ssh://git@github.com/libgit2/TestGitRepository',
          localPath: cloneDir.path,
          callbacks: callbacks,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('sucessfully clones repository with provided keypair from memory', () {
      final pubKey = File('test/assets/keys/id_rsa.pub').readAsStringSync();
      final privateKey = File('test/assets/keys/id_rsa').readAsStringSync();
      final keypair = KeypairFromMemory(
        username: 'git',
        pubKey: pubKey,
        privateKey: privateKey,
        passPhrase: 'empty',
      );
      final callbacks = Callbacks(credentials: keypair);

      final repo = Repository.clone(
        url: 'ssh://git@github.com/libgit2/TestGitRepository',
        localPath: cloneDir.path,
        callbacks: callbacks,
      );

      expect(repo.isEmpty, false);

      repo.free();
    });

    test('sucessfully clones repository with provided username and password',
        () {
      final userPass = const UserPass(
        username: 'libgit2',
        password: 'libgit2',
      );
      final callbacks = Callbacks(credentials: userPass);

      final repo = Repository.clone(
        url: 'https://github.com/libgit2/TestGitRepository',
        localPath: cloneDir.path,
        callbacks: callbacks,
      );

      expect(repo.isEmpty, false);

      repo.free();
    });
  });
}
