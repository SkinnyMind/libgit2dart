import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as bindings;
import 'bindings/object.dart' as object_bindings;
import 'bindings/refdb.dart' as refdb_bindings;
import 'bindings/repository.dart' as repository_bindings;
import 'blob.dart';
import 'commit.dart';
import 'oid.dart';
import 'reflog.dart';
import 'git_types.dart';
import 'repository.dart';
import 'tag.dart';
import 'tree.dart';
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
  List<String> get list => bindings.list(_repoPointer);

  /// Returns number of all the references that can be found in a repository.
  int get length => list.length;

  /// Returns a [Reference] by lookingup [name] in a repository.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference operator [](String name) {
    return Reference(bindings.lookup(repoPointer: _repoPointer, name: name));
  }

  /// Creates a new reference.
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
  Reference create({
    required String name,
    required Object target,
    bool force = false,
    String? logMessage,
  }) {
    late final Oid oid;
    late final bool isDirect;

    if (target is Oid) {
      oid = target;
      isDirect = true;
    } else if (isValidShaHex(target as String)) {
      final repo = Repository(_repoPointer);
      oid = Oid.fromSHA(repo: repo, sha: target);
      isDirect = true;
    } else {
      isDirect = false;
    }

    if (isDirect) {
      return Reference(bindings.createDirect(
        repoPointer: _repoPointer,
        name: name,
        oidPointer: oid.pointer,
        force: force,
        logMessage: logMessage,
      ));
    } else {
      return Reference(bindings.createSymbolic(
        repoPointer: _repoPointer,
        name: name,
        target: target as String,
        force: force,
        logMessage: logMessage,
      ));
    }
  }

  /// Suggests that the given refdb compress or optimize its references.
  /// This mechanism is implementation specific. For on-disk reference databases,
  /// for example, this may pack all loose references.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void compress() {
    final refdb = repository_bindings.refdb(_repoPointer);
    refdb_bindings.compress(refdb);
    refdb_bindings.free(refdb);
  }
}

class Reference {
  /// Initializes a new instance of the [Reference] class.
  /// Should be freed with `free()` to release allocated memory.
  Reference(this._refPointer);

  late Pointer<git_reference> _refPointer;

  /// Pointer to memory address for allocated reference object.
  Pointer<git_reference> get pointer => _refPointer;

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
  void setTarget({required String target, String? logMessage}) {
    late final Oid oid;
    final owner = bindings.owner(_refPointer);

    if (isValidShaHex(target)) {
      final repo = Repository(owner);
      oid = Oid.fromSHA(repo: repo, sha: target);
    } else {
      final ref = Reference(bindings.lookup(repoPointer: owner, name: target));
      oid = ref.target;
      ref.free();
    }

    if (type == ReferenceType.direct) {
      _refPointer = bindings.setTarget(
        refPointer: _refPointer,
        oidPointer: oid.pointer,
        logMessage: logMessage,
      );
    } else {
      _refPointer = bindings.setTargetSymbolic(
        refPointer: _refPointer,
        target: target,
        logMessage: logMessage,
      );
    }
  }

  /// Recursively peel reference until object of the specified [type] is found.
  ///
  /// The retrieved peeled object is owned by the repository and should be closed to release memory.
  ///
  /// If no [type] is provided, then the object will be peeled until a non-tag object is met.
  ///
  /// Returned object should be explicitly downcasted to one of four of git object types.
  ///
  /// ```dart
  /// final commit = ref.peel(GitObject.commit) as Commit;
  /// final tree = ref.peel(GitObject.tree) as Tree;
  /// ```
  ///
  /// Throws a [LibGit2Error] if error occured.
  Object peel([GitObject type = GitObject.any]) {
    final object = bindings.peel(refPointer: _refPointer, type: type.value);
    final objectType = object_bindings.type(object);

    if (objectType == GitObject.commit.value) {
      return Commit(object.cast());
    } else if (objectType == GitObject.tree.value) {
      return Tree(object.cast());
    } else if (objectType == GitObject.blob.value) {
      return Blob(object.cast());
    } else {
      return Tag(object.cast());
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
  void rename({
    required String newName,
    bool force = false,
    String? logMessage,
  }) {
    _refPointer = bindings.rename(
      refPointer: _refPointer,
      newName: newName,
      force: force,
      logMessage: logMessage,
    );
  }

  /// Checks if a reflog exists for the specified reference [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get hasLog {
    final owner = bindings.owner(_refPointer);
    return bindings.hasLog(repoPointer: owner, name: name);
  }

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
        bindings.compare(
          ref1Pointer: _refPointer,
          ref2Pointer: other._refPointer,
        );
  }

  @override
  int get hashCode => _refPointer.address.hashCode;

  /// Releases memory allocated for reference object.
  void free() => bindings.free(_refPointer);
}
