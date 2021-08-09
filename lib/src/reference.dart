import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as bindings;
import 'bindings/repository.dart' as repo_bindings;
import 'odb.dart';
import 'oid.dart';
import 'reflog.dart';
import 'repository.dart';
import 'util.dart';

enum ReferenceType { direct, symbolic }

class Reference {
  /// Initializes a new instance of the [Reference] class.
  /// Should be freed with `free()` to release allocated memory.
  Reference(this._refPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of the [Reference] class by creating a new reference.
  ///
  /// The reference will be created in the repository and written to the disk.
  /// The generated [Reference] object must be freed by the user.
  ///
  /// Valid reference names must follow one of two patterns:
  ///
  /// Top-level names must contain only capital letters and underscores, and must begin and end
  /// with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  /// Throws a [LibGit2Error] if a reference already exists with the given name
  /// unless force is true, in which case it will be overwritten.
  ///
  /// The message for the reflog will be ignored if the reference does not belong in the
  /// standard set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
  Reference.create({
    required Repository repository,
    required String name,
    required Object target,
    bool force = false,
    String? logMessage,
  }) {
    late final Oid oid;
    late final bool isDirect;

    if (target.runtimeType == Oid) {
      oid = target as Oid;
      isDirect = true;
    } else if (isValidShaHex(target as String)) {
      if (target.length == 40) {
        oid = Oid.fromSHA(target);
      } else {
        final shortOid = Oid.fromSHAn(target);
        final odb = repository.odb;
        oid = Oid(odb.existsPrefix(shortOid.pointer, target.length));
        odb.free();
      }
      isDirect = true;
    } else {
      isDirect = false;
    }

    if (isDirect) {
      _refPointer = bindings.createDirect(
        repository.pointer,
        name,
        oid.pointer,
        force,
        logMessage,
      );
    } else {
      _refPointer = bindings.createSymbolic(
        repository.pointer,
        name,
        target as String,
        force,
        logMessage,
      );
    }
  }

  /// Initializes a new instance of the [Reference] class by
  /// lookingup a reference by [name] in a [repository].
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference.get(Repository repository, String name) {
    libgit2.git_libgit2_init();
    _refPointer = bindings.lookup(repository.pointer, name);
  }

  /// Initializes a new instance of the [Reference] class by
  /// lookingup a reference by DWIMing it's short [name] in a [repository].
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference.getDWIM(Repository repository, String name) {
    libgit2.git_libgit2_init();
    _refPointer = bindings.lookupDWIM(repository.pointer, name);
  }

  /// Pointer to memory address for allocated reference object.
  late Pointer<git_reference> _refPointer;

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

  /// Conditionally creates a new reference with the same name as the given reference
  /// but a different OID target.
  ///
  /// The new reference will be written to disk, overwriting the given reference.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setTarget(String target, [String? logMessage]) {
    late final Oid oid;

    if (isValidShaHex(target)) {
      if (target.length == 40) {
        oid = Oid.fromSHA(target);
      } else {
        final shortOid = Oid.fromSHAn(target);
        final odb = Odb(repo_bindings.odb(owner));
        oid = Oid(odb.existsPrefix(shortOid.pointer, target.length));
        odb.free();
      }
    } else {
      final ref = Reference(bindings.lookup(owner, target));
      oid = ref.target;
      ref.free();
    }

    if (type == ReferenceType.direct) {
      _refPointer = bindings.setTarget(_refPointer, oid.pointer, logMessage);
    } else {
      _refPointer = bindings.setTargetSymbolic(_refPointer, target, logMessage);
    }
  }

  /// Returns the full name of a reference.
  String get name => bindings.name(_refPointer);

  /// Returns the reference's short name.
  ///
  /// This will transform the reference name into a name "human-readable" version.
  /// If no shortname is appropriate, it will return the full name.
  String get shorthand => bindings.shorthand(_refPointer);

  /// Renames an existing reference.
  ///
  /// This method works for both direct and symbolic references.
  ///
  /// The new name will be checked for validity.
  ///
  /// If the force flag is not enabled, and there's already a reference with the given name,
  /// the renaming will fail.
  ///
  /// IMPORTANT: The user needs to write a proper reflog entry if the reflog is enabled for
  /// the repository. We only rename the reflog if it exists.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void rename(String newName, {bool force = false, String? logMessage}) {
    _refPointer = bindings.rename(_refPointer, newName, force, logMessage);
  }

  /// Returns a list with all the references that can be found in a [repository].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repository) {
    return bindings.list(repository.pointer);
  }

  /// Checks if a reflog exists for the specified reference [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static bool hasLog(Repository repository, String name) {
    return bindings.hasLog(repository.pointer, name);
  }

  /// Returns a list with entries of reference log.
  List<RefLogEntry> get log {
    final reflog = RefLog(this);
    var log = <RefLogEntry>[];

    for (var i = 0; i < reflog.count; i++) {
      log.add(reflog.entryAt(i));
    }

    return log;
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
    bindings.free(_refPointer);
    libgit2.git_libgit2_shutdown();
  }
}
