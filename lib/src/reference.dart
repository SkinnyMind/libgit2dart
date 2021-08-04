import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as bindings;
import 'repository.dart';
import 'oid.dart';
import 'util.dart';

enum ReferenceType { direct, symbolic }

class Reference {
  /// Initializes a new instance of the [Reference] class.
  /// Should be freed with `free()` to release allocated memory.
  Reference(this._refPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of the [Reference] class by
  /// lookingup a reference by [name] in a [repository].
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference.lookup(Repository repository, String name) {
    libgit2.git_libgit2_init();

    try {
      _refPointer = bindings.lookup(repository.pointer, name);
    } catch (e) {
      rethrow;
    }
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

  /// Returns the SHA hex of the OID pointed to by a reference.
  String get target {
    late final Pointer<git_oid>? oidPointer;
    final sha = '';

    if (type == ReferenceType.direct) {
      oidPointer = bindings.target(_refPointer);
    } else {
      oidPointer = bindings.target(bindings.resolve(_refPointer));
    }

    return oidPointer == nullptr ? sha : Oid(oidPointer!).sha;
  }

  /// Returns the full name of a reference.
  String get name => bindings.name(_refPointer);

  /// Returns a list with all the references that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Pointer<git_repository> repo) {
    try {
      return bindings.list(repo);
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a reflog exists for the specified reference [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static bool hasLog(Repository repo, String name) {
    try {
      return bindings.hasLog(repo.pointer, name);
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a reference is a local branch.
  bool get isBranch => bindings.isBranch(_refPointer);

  /// Checks if a reference is a note.
  bool get isNote => bindings.isNote(_refPointer);

  /// Check if a reference is a remote tracking branch.
  bool get isRemote => bindings.isRemote(_refPointer);

  /// Check if a reference is a tag.
  bool get isTag => bindings.isTag(_refPointer);

  /// Releases memory allocated for reference object.
  void free() {
    calloc.free(_refPointer);
    libgit2.git_libgit2_shutdown();
  }
}
