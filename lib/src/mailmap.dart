import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/mailmap.dart' as bindings;
import 'util.dart';

class Mailmap {
  /// Initializes a new instance of [Mailmap] class.
  ///
  /// This object is empty, so you'll have to add a mailmap file before you can
  /// do anything with it. Must be freed with `free()`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Mailmap.empty() {
    libgit2.git_libgit2_init();

    _mailmapPointer = bindings.init();
  }

  /// Initializes a new instance of [Mailmap] class from provided buffer.
  ///
  /// Must be freed with `free()`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Mailmap.fromBuffer(String buffer) {
    libgit2.git_libgit2_init();

    _mailmapPointer = bindings.fromBuffer(buffer);
  }

  /// Initializes a new instance of [Mailmap] class from a repository, loading
  /// mailmap files based on the repository's configuration.
  ///
  /// Mailmaps are loaded in the following order:
  ///
  /// 1. `.mailmap` in the root of the repository's working directory, if present.
  /// 2. The blob object identified by the `mailmap.blob` config entry, if set.
  ///   NOTE: `mailmap.blob` defaults to `HEAD:.mailmap` in bare repositories
  /// 3. The path in the `mailmap.file` config entry, if set.
  ///
  /// Must be freed with `free()`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Mailmap.fromRepository(Repository repo) {
    _mailmapPointer = bindings.fromRepository(repo.pointer);
  }

  /// Pointer to memory address for allocated mailmap object.
  late final Pointer<git_mailmap> _mailmapPointer;

  /// Returns list containing resolved [name] and [email] to the corresponding real name
  /// and real email respectively.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> resolve({
    required String name,
    required String email,
  }) {
    return bindings.resolve(
      mailmapPointer: _mailmapPointer,
      name: name,
      email: email,
    );
  }

  /// Resolves a signature to use real names and emails with a mailmap.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Signature resolveSignature(Signature signature) {
    return Signature(bindings.resolveSignature(
      mailmapPointer: _mailmapPointer,
      signaturePointer: signature.pointer,
    ));
  }

  /// Adds a single entry to the given mailmap object. If the entry already exists,
  /// it will be replaced with the new entry.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addEntry({
    String? realName,
    String? realEmail,
    String? replaceName,
    required String replaceEmail,
  }) {
    bindings.addEntry(
      mailmapPointer: _mailmapPointer,
      realName: realName,
      realEmail: realEmail,
      replaceName: replaceName,
      replaceEmail: replaceEmail,
    );
  }

  /// Releases memory allocated for mailmap object.
  void free() => bindings.free(_mailmapPointer);
}
