import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;
import 'package:libgit2dart/src/bindings/refdb.dart' as refdb_bindings;
import 'package:libgit2dart/src/bindings/reference.dart' as bindings;
import 'package:libgit2dart/src/bindings/repository.dart'
    as repository_bindings;
import 'package:meta/meta.dart';

@immutable
class Reference extends Equatable {
  /// Initializes a new instance of the [Reference] class.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Reference.create]
  /// - [Reference.lookup]
  @internal
  Reference(this._refPointer) {
    _finalizer.attach(this, _refPointer, detach: this);
  }

  /// Creates a new reference for provided [target].
  ///
  /// The reference will be created in the [repo]sitory and written to the disk.
  ///
  /// Valid reference [name]s must follow one of two patterns:
  /// - Top-level names must contain only capital letters and underscores, and
  /// must begin and end with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// - Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if a reference already exists with the given
  /// [name] unless [force] is true, in which case it will be overwritten.
  ///
  /// The [logMessage] message for the reflog will be ignored if the reference
  /// does not belong in the standard set (HEAD, branches and remote-tracking
  /// branches) and it does not have a reflog.
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if provided
  /// [target] is not Oid or String reference name.
  Reference.create({
    required Repository repo,
    required String name,
    required Object target,
    bool force = false,
    String? logMessage,
  }) {
    if (target is Oid) {
      _refPointer = bindings.createDirect(
        repoPointer: repo.pointer,
        name: name,
        oidPointer: target.pointer,
        force: force,
        logMessage: logMessage,
      );
    } else if (target is String) {
      _refPointer = bindings.createSymbolic(
        repoPointer: repo.pointer,
        name: name,
        target: target,
        force: force,
        logMessage: logMessage,
      );
    } else {
      throw ArgumentError.value(
        '$target must be either Oid or String reference name',
      );
    }
    _finalizer.attach(this, _refPointer, detach: this);
  }

  /// Lookups reference [name] in a [repo]sitory.
  ///
  /// The [name] will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference.lookup({required Repository repo, required String name}) {
    _refPointer = bindings.lookup(repoPointer: repo.pointer, name: name);
    _finalizer.attach(this, _refPointer, detach: this);
  }

  late final Pointer<git_reference> _refPointer;

  /// Pointer to memory address for allocated reference object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_reference> get pointer => _refPointer;

  /// Deletes an existing reference with provided [name].
  ///
  /// This method works for both direct and symbolic references.
  static void delete({required Repository repo, required String name}) {
    final ref = Reference.lookup(repo: repo, name: name);
    bindings.delete(ref.pointer);
  }

  /// Renames an existing reference with provided [oldName].
  ///
  /// This method works for both direct and symbolic references.
  ///
  /// The [newName] will be checked for validity.
  ///
  /// If the [force] flag is set to false, and there's already a reference with
  /// the given name, the renaming will fail.
  ///
  /// IMPORTANT: The user needs to write a proper reflog entry [logMessage] if
  /// the reflog is enabled for the repository. We only rename the reflog if it
  /// exists.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void rename({
    required Repository repo,
    required String oldName,
    required String newName,
    bool force = false,
    String? logMessage,
  }) {
    final ref = Reference.lookup(repo: repo, name: oldName);
    bindings.rename(
      refPointer: ref.pointer,
      newName: newName,
      force: force,
      logMessage: logMessage,
    );
  }

  /// Updates the [target] of reference with provided [name].
  ///
  /// [target] being either Oid for direct reference or string reference name
  /// for symbolic reference.
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if [target]
  /// is not [Oid] or string.
  static void setTarget({
    required Repository repo,
    required String name,
    required Object target,
    String? logMessage,
  }) {
    final ref = Reference.lookup(repo: repo, name: name);
    if (target is Oid) {
      bindings.setTarget(
        refPointer: ref.pointer,
        oidPointer: target.pointer,
        logMessage: logMessage,
      );
    } else if (target is String) {
      bindings.setTargetSymbolic(
        refPointer: ref.pointer,
        target: target,
        logMessage: logMessage,
      );
    } else {
      throw ArgumentError.value(
        '$target must be either Oid or String reference name',
      );
    }
  }

  /// List of all the references names that can be found in a [repo]sitory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repo) => bindings.list(repo.pointer);

  /// Suggests that the [repo]sitory's refdb compress or optimize its
  /// references. This mechanism is implementation specific. For on-disk
  /// reference databases, for example, this may pack all loose references.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void compress(Repository repo) {
    final refdb = repository_bindings.refdb(repo.pointer);
    refdb_bindings.compress(refdb);
    refdb_bindings.free(refdb);
  }

  /// Ensures there is a reflog for a particular reference.
  ///
  /// Makes sure that successive updates to the reference will append to its
  /// log.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void ensureLog({
    required Repository repo,
    required String refName,
  }) {
    bindings.ensureLog(repoPointer: repo.pointer, refName: refName);
  }

  /// Creates a copy of an existing reference.
  Reference duplicate() => Reference(bindings.duplicate(_refPointer));

  /// Type of the reference.
  ReferenceType get type {
    return bindings.referenceType(_refPointer) == 1
        ? ReferenceType.direct
        : ReferenceType.symbolic;
  }

  /// [Oid] pointed to by a reference.
  ///
  /// Throws an [Exception] if error occured.
  Oid get target {
    return type == ReferenceType.direct
        ? Oid(bindings.target(_refPointer))
        : Oid(bindings.target(bindings.resolve(_refPointer)));
  }

  /// Recursively peel reference until object of the specified [type] is found.
  ///
  /// The retrieved peeled object is owned by the repository and should be
  /// freed to release memory.
  ///
  /// If no [type] is provided, then the object will be peeled until a non-tag
  /// object is met.
  ///
  /// Returned object should be explicitly downcasted to one of four of git
  /// object types.
  ///
  /// ```dart
  /// final commit = ref.peel(GitObject.commit) as Commit;
  /// final tree = ref.peel(GitObject.tree) as Tree;
  /// final blob = ref.peel(GitObject.blob) as Blob;
  /// final tag = ref.peel(GitObject.tag) as Tag;
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

  /// Full name of a reference.
  String get name => bindings.name(_refPointer);

  /// Reference's short name.
  ///
  /// This will transform the reference name into a name "human-readable"
  /// version. If no shortname is appropriate, it will return the full name.
  String get shorthand => bindings.shorthand(_refPointer);

  /// Whether reflog exists for the specified reference [name].
  bool get hasLog {
    return bindings.hasLog(
      repoPointer: bindings.owner(_refPointer),
      name: name,
    );
  }

  /// [RefLog] object.
  RefLog get log => RefLog(this);

  /// Whether reference is a local branch.
  bool get isBranch => bindings.isBranch(_refPointer);

  /// Whether reference is a note.
  bool get isNote => bindings.isNote(_refPointer);

  /// Whether reference is a remote tracking branch.
  bool get isRemote => bindings.isRemote(_refPointer);

  /// Whether reference is a tag.
  bool get isTag => bindings.isTag(_refPointer);

  /// Releases memory allocated for reference object.
  void free() {
    bindings.free(_refPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Reference{name: $name, target: $target, type: $type, '
        'isBranch: $isBranch, isNote: $isNote, isRemote: $isRemote, '
        'isTag: $isTag}';
  }

  @override
  List<Object?> get props => [target];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_reference>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
