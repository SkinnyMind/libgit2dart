import 'package:libgit2dart/libgit2dart.dart';

/// Abstract class. Use one of the implementations:
/// - [UserPass]
/// - [Keypair]
/// - [KeypairFromAgent]
/// - [KeypairFromMemory]
abstract class Credentials {
  /// Returns type of authentication method.
  GitCredential get credentialType;
}

/// Plain-text username and password credential.
class UserPass implements Credentials {
  const UserPass({required this.username, required this.password});

  /// The username to authenticate with.
  final String username;

  /// The password of the credential.
  final String password;

  @override
  GitCredential get credentialType => GitCredential.userPassPlainText;

  @override
  String toString() {
    return 'UserPass{username: $username, password: $password}';
  }
}

/// Passphrase-protected ssh key credential.
class Keypair implements Credentials {
  const Keypair({
    required this.username,
    required this.pubKey,
    required this.privateKey,
    required this.passPhrase,
  });

  /// The username to authenticate with.
  final String username;

  /// The path to the public key of the credential.
  final String pubKey;

  /// The path to the private key of the credential.
  final String privateKey;

  /// The passphrase of the credential.
  final String passPhrase;

  @override
  GitCredential get credentialType => GitCredential.sshKey;

  @override
  String toString() {
    return 'Keypair{username: $username, pubKey: $pubKey, '
        'privateKey: $privateKey, passPhrase: $passPhrase}';
  }
}

/// Ssh key credential used for querying an ssh-agent.
class KeypairFromAgent implements Credentials {
  const KeypairFromAgent(this.username);

  /// The username to authenticate with.
  final String username;

  @override
  GitCredential get credentialType => GitCredential.sshKey;

  @override
  String toString() => 'KeypairFromAgent{username: $username}';
}

/// Ssh key credential used for reading the keys from memory.
class KeypairFromMemory implements Credentials {
  const KeypairFromMemory({
    required this.username,
    required this.pubKey,
    required this.privateKey,
    required this.passPhrase,
  });

  /// The username to authenticate with.
  final String username;

  /// The path to the public key of the credential.
  final String pubKey;

  /// The path to the private key of the credential.
  final String privateKey;

  /// The passphrase of the credential.
  final String passPhrase;

  @override
  GitCredential get credentialType => GitCredential.sshMemory;

  @override
  String toString() {
    return 'KeypairFromMemory{username: $username, pubKey: $pubKey, '
        'privateKey: $privateKey, passPhrase: $passPhrase}';
  }
}
