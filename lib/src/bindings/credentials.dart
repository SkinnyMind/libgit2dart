import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Create a credential to specify a username.
///
/// This is used with ssh authentication to query for the username if none is
/// specified in the url.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_credential> username(String username) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toNativeUtf8().cast<Int8>();

  final error = libgit2.git_credential_username_new(out, usernameC);

  calloc.free(usernameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new plain-text username and password credential object.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_credential> userPass({
  required String username,
  required String password,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toNativeUtf8().cast<Int8>();
  final passwordC = password.toNativeUtf8().cast<Int8>();

  final error =
      libgit2.git_credential_userpass_plaintext_new(out, usernameC, passwordC);

  calloc.free(usernameC);
  calloc.free(passwordC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new passphrase-protected ssh key credential object.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_credential> sshKey({
  required String username,
  required String publicKey,
  required String privateKey,
  required String passPhrase,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toNativeUtf8().cast<Int8>();
  final publicKeyC = publicKey.toNativeUtf8().cast<Int8>();
  final privateKeyC = privateKey.toNativeUtf8().cast<Int8>();
  final passPhraseC = passPhrase.toNativeUtf8().cast<Int8>();

  final error = libgit2.git_credential_ssh_key_new(
    out,
    usernameC,
    publicKeyC,
    privateKeyC,
    passPhraseC,
  );

  calloc.free(usernameC);
  calloc.free(publicKeyC);
  calloc.free(privateKeyC);
  calloc.free(passPhraseC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new ssh key credential object used for querying an ssh-agent.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_credential> sshKeyFromAgent(String username) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toNativeUtf8().cast<Int8>();

  final error = libgit2.git_credential_ssh_key_from_agent(out, usernameC);

  calloc.free(usernameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new ssh key credential object reading the keys from memory.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_credential> sshKeyFromMemory({
  required String username,
  required String publicKey,
  required String privateKey,
  required String passPhrase,
}) {
  final out = calloc<Pointer<git_credential>>();
  final usernameC = username.toNativeUtf8().cast<Int8>();
  final publicKeyC = publicKey.toNativeUtf8().cast<Int8>();
  final privateKeyC = privateKey.toNativeUtf8().cast<Int8>();
  final passPhraseC = passPhrase.toNativeUtf8().cast<Int8>();

  final error = libgit2.git_credential_ssh_key_memory_new(
    out,
    usernameC,
    publicKeyC,
    privateKeyC,
    passPhraseC,
  );

  calloc.free(usernameC);
  calloc.free(publicKeyC);
  calloc.free(privateKeyC);
  calloc.free(passPhraseC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}
