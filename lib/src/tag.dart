import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;
import 'package:libgit2dart/src/bindings/tag.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Tag extends Equatable {
  /// Initializes a new instance of [Tag] class from provided pointer to
  /// tag object in memory.
  ///
  /// Note: For internal use. Use [Tag.lookup] instead.
  @internal
  Tag(this._tagPointer) {
    _finalizer.attach(this, _tagPointer, detach: this);
  }

  /// Lookups tag object for provided [oid] in a [repo]sitory.
  Tag.lookup({required Repository repo, required Oid oid}) {
    _tagPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
    _finalizer.attach(this, _tagPointer, detach: this);
  }

  /// Pointer to memory address for allocated tag object.
  late final Pointer<git_tag> _tagPointer;

  /// Creates a new annotated tag in the repository for provided [target]
  /// object.
  ///
  /// A new reference will also be created in the `/refs/tags` folder pointing
  /// to this tag object. If [force] is true and a reference already exists
  /// with the given name, it'll be replaced.
  ///
  /// The [tagName] will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// [repo] is the repository where to store the tag.
  ///
  /// [tagName] is the name for the tag. This name is validated for
  /// consistency. It should also not conflict with an already existing tag
  /// name.
  ///
  /// [target] is the object to which this tag points. This object must belong
  /// to the given [repo].
  ///
  /// [targetType] is one of the [GitObject] basic types: commit, tree, blob or
  /// tag.
  ///
  /// [tagger] is the signature of the tagger for this tag, and of the tagging
  /// time.
  ///
  /// [message] is the full message for this tag.
  ///
  /// [force] determines whether existing reference with the same [tagName]
  /// should be replaced.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createAnnotated({
    required Repository repo,
    required String tagName,
    required Oid target,
    required GitObject targetType,
    required Signature tagger,
    required String message,
    bool force = false,
  }) {
    final object = object_bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: target.pointer,
      type: targetType.value,
    );

    final result = bindings.createAnnotated(
      repoPointer: repo.pointer,
      tagName: tagName,
      targetPointer: object,
      taggerPointer: tagger.pointer,
      message: message,
      force: force,
    );

    object_bindings.free(object);

    return Oid(result);
  }

  /// Creates a new lightweight tag in the repository for provided [target]
  /// object.
  ///
  /// A new reference will also be created in the `/refs/tags` folder pointing
  /// to this tag object. If [force] is true and a reference already exists
  /// with the given name, it'll be replaced.
  ///
  /// The [tagName] will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// [repo] is the repository where to store the tag.
  ///
  /// [tagName] is the name for the tag. This name is validated for
  /// consistency. It should also not conflict with an already existing tag
  /// name.
  ///
  /// [target] is the object to which this tag points. This object must belong
  /// to the given [repo].
  ///
  /// [targetType] is one of the [GitObject] basic types: commit, tree, blob or
  /// tag.
  ///
  /// [force] determines whether existing reference with the same [tagName]
  /// should be replaced.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void createLightweight({
    required Repository repo,
    required String tagName,
    required Oid target,
    required GitObject targetType,
    bool force = false,
  }) {
    final object = object_bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: target.pointer,
      type: targetType.value,
    );

    bindings.createLightweight(
      repoPointer: repo.pointer,
      tagName: tagName,
      targetPointer: object,
      force: force,
    );

    object_bindings.free(object);
  }

  /// Deletes an existing tag reference with provided [name] in a [repo]sitory.
  ///
  /// The tag [name] will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({required Repository repo, required String name}) {
    bindings.delete(repoPointer: repo.pointer, tagName: name);
  }

  /// Returns a list with all the tags names in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repo) {
    return bindings.list(repo.pointer);
  }

  /// Tagged object (commit, tree, blob, tag) of a tag.
  ///
  /// This method performs a repository lookup for the given object and returns
  /// it.
  ///
  /// Returned object should be explicitly downcasted to one of four of git
  /// object types.
  ///
  /// ```dart
  /// final commit = tag.target as Commit;
  /// final tree = tag.target as Tree;
  /// final blob = tag.target as Blob;
  /// final tag = tag.target as Tag;
  /// ```
  ///
  /// Throws a [LibGit2Error] if error occured.
  Object get target {
    final type = bindings.targetType(_tagPointer);
    final object = bindings.target(_tagPointer);

    if (type == GitObject.commit.value) {
      return Commit(object.cast());
    } else if (type == GitObject.tree.value) {
      return Tree(object.cast());
    } else if (type == GitObject.blob.value) {
      return Blob(object.cast());
    } else {
      return Tag(object.cast());
    }
  }

  /// The type of a tag's tagged object.
  GitObject get targetType {
    final type = bindings.targetType(_tagPointer);
    return GitObject.values.firstWhere((e) => type & e.value == e.value);
  }

  /// [Oid] of the tagged object of a tag.
  Oid get targetOid => Oid(bindings.targetOid(_tagPointer));

  /// [Oid] of a tag.
  Oid get oid => Oid(bindings.id(_tagPointer));

  /// Name of a tag.
  String get name => bindings.name(_tagPointer);

  /// Message of a tag.
  String get message => bindings.message(_tagPointer);

  /// Tagger (author) of a tag if there is one.
  Signature? get tagger {
    final sigPointer = bindings.tagger(_tagPointer);
    return sigPointer != nullptr ? Signature(sigPointer) : null;
  }

  /// Releases memory allocated for tag object.
  void free() {
    bindings.free(_tagPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Tag{oid: $oid, name: $name, message: $message, target: $target, '
        'tagger: $tagger}';
  }

  @override
  List<Object?> get props => [name];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_tag>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
