import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Create a new plain-text username and password credential object.
Pointer<git_credential> userPass({
  required String username,
  required String password,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toChar();
  final passwordC = password.toChar();

  libgit2.git_credential_userpass_plaintext_new(out, usernameC, passwordC);

  final result = out.value;

  calloc.free(out);
  calloc.free(usernameC);
  calloc.free(passwordC);

  return result;
}

/// Create a new passphrase-protected ssh key credential object.
Pointer<git_credential> sshKey({
  required String username,
  required String publicKey,
  required String privateKey,
  required String passPhrase,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toChar();
  final publicKeyC = publicKey.toChar();
  final privateKeyC = privateKey.toChar();
  final passPhraseC = passPhrase.toChar();

  libgit2.git_credential_ssh_key_new(
    out,
    usernameC,
    publicKeyC,
    privateKeyC,
    passPhraseC,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(usernameC);
  calloc.free(publicKeyC);
  calloc.free(privateKeyC);
  calloc.free(passPhraseC);

  return result;
}

/// Create a new ssh key credential object used for querying an ssh-agent.
Pointer<git_credential> sshKeyFromAgent(String username) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toChar();

  libgit2.git_credential_ssh_key_from_agent(out, usernameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(usernameC);

  return result;
}

/// Create a new ssh key credential object reading the keys from memory.
Pointer<git_credential> sshKeyFromMemory({
  required String username,
  required String publicKey,
  required String privateKey,
  required String passPhrase,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toChar();
  final publicKeyC = publicKey.toChar();
  final privateKeyC = privateKey.toChar();
  final passPhraseC = passPhrase.toChar();

  libgit2.git_credential_ssh_key_memory_new(
    out,
    usernameC,
    publicKeyC,
    privateKeyC,
    passPhraseC,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(usernameC);
  calloc.free(publicKeyC);
  calloc.free(privateKeyC);
  calloc.free(passPhraseC);

  return result;
}
