import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/mailmap.dart' as bindings;
import 'package:libgit2dart/src/util.dart';

class Mailmap {
  /// Initializes a new instance of [Mailmap] class.
  ///
  /// This object is empty, so you'll have to add a mailmap file before you can
  /// do anything with it.
  Mailmap.empty() {
    libgit2.git_libgit2_init();

    _mailmapPointer = bindings.init();
    _finalizer.attach(this, _mailmapPointer, detach: this);
  }

  /// Initializes a new instance of [Mailmap] class from provided buffer.
  Mailmap.fromBuffer(String buffer) {
    libgit2.git_libgit2_init();

    _mailmapPointer = bindings.fromBuffer(buffer);
    _finalizer.attach(this, _mailmapPointer, detach: this);
  }

  /// Initializes a new instance of [Mailmap] class from a [repo]sitory, loading
  /// mailmap files based on the repository's configuration.
  ///
  /// Mailmaps are loaded in the following order:
  ///
  /// 1. `.mailmap` in the root of the repository's working directory, if
  /// present.
  /// 2. The blob object identified by the `mailmap.blob` config entry, if set.
  ///   NOTE: `mailmap.blob` defaults to `HEAD:.mailmap` in bare repositories.
  /// 3. The path in the `mailmap.file` config entry, if set.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Mailmap.fromRepository(Repository repo) {
    _mailmapPointer = bindings.fromRepository(repo.pointer);
    _finalizer.attach(this, _mailmapPointer, detach: this);
  }

  /// Pointer to memory address for allocated mailmap object.
  late final Pointer<git_mailmap> _mailmapPointer;

  /// Returns list containing resolved [name] and [email] to the corresponding
  /// real name and real email respectively.
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

  /// Resolves a [signature] to use real names and emails with a mailmap.
  Signature resolveSignature(Signature signature) {
    return Signature(
      bindings.resolveSignature(
        mailmapPointer: _mailmapPointer,
        signaturePointer: signature.pointer,
      ),
    );
  }

  /// Adds a single entry to the given mailmap object. If the entry already
  /// exists, it will be replaced with the new entry.
  ///
  /// Throws a [ArgumentError] if [replaceEmail] is empty string.
  void addEntry({
    String? realName,
    String? realEmail,
    String? replaceName,
    required String replaceEmail,
  }) {
    if (replaceEmail.trim().isEmpty) {
      throw ArgumentError.value("replaceEmail can't be empty");
    } else {
      bindings.addEntry(
        mailmapPointer: _mailmapPointer,
        realName: realName,
        realEmail: realEmail,
        replaceName: replaceName,
        replaceEmail: replaceEmail,
      );
    }
  }

  /// Releases memory allocated for mailmap object.
  void free() {
    bindings.free(_mailmapPointer);
    _finalizer.detach(this);
  }
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_mailmap>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
