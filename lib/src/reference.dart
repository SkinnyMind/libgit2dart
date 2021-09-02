import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as bindings;
import 'oid.dart';
import 'reflog.dart';
import 'enums.dart';
import 'repository.dart';
import 'util.dart';

class References {
  /// Initializes a new instance of the [References] class
  /// from provided [Repository] object.
  References(Repository repo) {
    _repoPointer = repo.pointer;
  }

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Returns a list of all the references that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> list() => bindings.list(_repoPointer);

  /// Returns a [Reference] by lookingup [name] in a repository.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference operator [](String name) {
    final refPointer = bindings.lookup(_repoPointer, name);
    return Reference(_repoPointer, refPointer);
  }
}

class Reference {
  /// Initializes a new instance of the [Reference] class.
  /// Should be freed with `free()` to release allocated memory.
  Reference(this._repoPointer, this._refPointer);

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
    required Repository repo,
    required String name,
    required Pointer<git_oid> oid,
    required bool force,
    String? logMessage,
  }) {
    _repoPointer = repo.pointer;
    _refPointer = bindings.createDirect(
      repo.pointer,
      name,
      oid,
      force,
      logMessage,
    );
  }

  /// Initializes a new instance of the [Reference] class by creating a new symbolic reference.
  ///
  /// A symbolic reference is a reference name that refers to another reference name.
  /// If the other name moves, the symbolic name will move, too. As a simple example,
  /// the "HEAD" reference might refer to "refs/heads/master" while on the "master" branch
  /// of a repository.
  ///
  /// The symbolic reference will be created in the repository and written to the disk.
  /// The generated reference object must be freed by the user.
  ///
  /// Valid reference names must follow one of two patterns:
  ///
  /// Top-level names must contain only capital letters and underscores, and must begin and end
  /// with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have special
  /// meaning to revparse.
  /// This function will throw an [LibGit2Error] if a reference already exists with the given
  /// name unless force is true, in which case it will be overwritten.
  ///
  /// The message for the reflog will be ignored if the reference does not belong in the standard
  /// set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
  Reference.createSymbolic({
    required Repository repo,
    required String name,
    required String target,
    required bool force,
    String? logMessage,
  }) {
    _repoPointer = repo.pointer;
    _refPointer = bindings.createSymbolic(
      repo.pointer,
      name,
      target,
      force,
      logMessage,
    );
  }

  /// Pointer to memory address for allocated reference object.
  late Pointer<git_reference> _refPointer;

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Returns the type of the reference.
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
      final repo = Repository(_repoPointer);
      oid = Oid.fromSHA(repo, target);
    } else {
      final ref = Reference(
        _repoPointer,
        bindings.lookup(_repoPointer, target),
      );
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

  /// Checks if a reflog exists for the specified reference [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get hasLog => bindings.hasLog(_repoPointer, name);

  /// Returns a [RefLog] object.
  ///
  /// Should be freed when no longer needed.
  RefLog get log => RefLog(this);

  /// Checks if a reference is a local branch.
  bool get isBranch => bindings.isBranch(_refPointer);

  /// Checks if a reference is a note.
  bool get isNote => bindings.isNote(_refPointer);

  /// Check if a reference is a remote tracking branch.
  bool get isRemote => bindings.isRemote(_refPointer);

  /// Check if a reference is a tag.
  bool get isTag => bindings.isTag(_refPointer);

  /// Returns the repository where a reference resides.
  Repository get owner => Repository(bindings.owner(_refPointer));

  /// Delete an existing reference.
  ///
  /// This method works for both direct and symbolic references.
  /// The reference will be immediately removed on disk but the memory will not be freed.
  ///
  /// Throws a [LibGit2Error] if the reference has changed from the time it was looked up.
  void delete() => bindings.delete(_refPointer);

  @override
  bool operator ==(other) {
    return (other is Reference) &&
        bindings.compare(_refPointer, other._refPointer);
  }

  @override
  int get hashCode => _refPointer.address.hashCode;

  /// Releases memory allocated for reference object.
  void free() => bindings.free(_refPointer);
}
