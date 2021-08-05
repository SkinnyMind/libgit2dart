import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as bindings;
import 'oid.dart';
import 'util.dart';

enum ReferenceType { direct, symbolic }

class Reference {
  /// Initializes a new instance of the [Reference] class.
  /// Should be freed with `free()` to release allocated memory.
  Reference(this._refPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of the [Reference] class by creating a new direct reference.
  ///
  /// The direct reference will be created in the repository and written to the disk.
  /// The generated [Reference] object must be freed by the user.
  ///
  /// Valid reference names must follow one of two patterns:
  ///
  /// Top-level names must contain only capital letters and underscores, and must begin and end
  /// with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if a reference already exists with the given name
  /// unless force is true, in which case it will be overwritten.
  ///
  /// The message for the reflog will be ignored if the reference does not belong in the
  /// standard set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
  Reference.createDirect({
    required Pointer<git_repository> repo,
    required String name,
    required Pointer<git_oid> oid,
    required bool force,
    required String logMessage,
  }) {
    _refPointer = bindings.createDirect(repo, name, oid, force, logMessage);
  }

  /// Initializes a new instance of the [Reference] class by
  /// lookingup a reference by [name] in a repository.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference.lookup(Pointer<git_repository> repo, String name) {
    libgit2.git_libgit2_init();
    _refPointer = bindings.lookup(repo, name);
  }

  /// Pointer to memory address for allocated reference object.
  late final Pointer<git_reference> _refPointer;

  /// Checks if the reference [name] is well-formed.
  ///
  /// Valid reference names must follow one of two patterns:
  ///
  /// Top-level names must contain only capital letters and underscores,
  /// and must begin and end with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// Names prefixed with "refs/" can be almost anything. You must avoid
  /// the characters '~', '^', ':', '\', '?', '[', and '*', and the sequences ".."
  /// and "@{" which have special meaning to revparse.
  static bool isValidName(String name) {
    libgit2.git_libgit2_init();
    final result = bindings.isValidName(name);
    libgit2.git_libgit2_shutdown();

    return result;
  }

  /// Returns the type of the reference
  ReferenceType get type {
    return bindings.referenceType(_refPointer) == 1
        ? ReferenceType.direct
        : ReferenceType.symbolic;
  }

  /// Returns the OID pointed to by a reference.
  ///
  /// Throws an exception if error occured.
  Oid get target {
    late final Pointer<git_oid> oidPointer;

    if (type == ReferenceType.direct) {
      oidPointer = bindings.target(_refPointer);
    } else {
      oidPointer = bindings.target(bindings.resolve(_refPointer));
    }
    return Oid(oidPointer);
  }

  /// Returns the full name of a reference.
  String get name => bindings.name(_refPointer);

  /// Returns a list with all the references that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Pointer<git_repository> repo) {
    return bindings.list(repo);
  }

  /// Checks if a reflog exists for the specified reference [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static bool hasLog(Pointer<git_repository> repo, String name) {
    return bindings.hasLog(repo, name);
  }

  /// Checks if a reference is a local branch.
  bool get isBranch => bindings.isBranch(_refPointer);

  /// Checks if a reference is a note.
  bool get isNote => bindings.isNote(_refPointer);

  /// Check if a reference is a remote tracking branch.
  bool get isRemote => bindings.isRemote(_refPointer);

  /// Check if a reference is a tag.
  bool get isTag => bindings.isTag(_refPointer);

  /// Returns the repository where a reference resides.
  Pointer<git_repository> get owner => bindings.owner(_refPointer);

  /// Delete an existing reference.
  ///
  /// This method works for both direct and symbolic references.
  /// The reference will be immediately removed on disk but the memory will not be freed.
  ///
  /// Throws a [LibGit2Error] if the reference has changed from the time it was looked up.
  void delete() => bindings.delete(_refPointer);

  /// Releases memory allocated for reference object.
  void free() {
    calloc.free(_refPointer);
    libgit2.git_libgit2_shutdown();
  }
}
