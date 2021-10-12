import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/tag.dart' as bindings;
import 'bindings/object.dart' as object_bindings;

class Tag {
  /// Initializes a new instance of [Tag] class from provided pointer to
  /// tag object in memory.
  ///
  /// Should be freed to release allocated memory.
  Tag(this._tagPointer);

  /// Lookups tag object for provided [id] in a [repo]sitory.
  ///
  /// Should be freed to release allocated memory.
  Tag.lookup({required Repository repo, required Oid id}) {
    _tagPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: id.pointer,
    );
  }

  late final Pointer<git_tag> _tagPointer;

  /// Pointer to memory address for allocated tag object.
  Pointer<git_tag> get pointer => _tagPointer;

  /// Creates a new tag in the repository for provided [target] object.
  ///
  /// A new reference will also be created pointing to this tag object. If [force] is true
  /// and a reference already exists with the given name, it'll be replaced.
  ///
  /// The [message] will not be cleaned up.
  ///
  /// The tag name will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
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

    final result = bindings.create(
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

  /// Deletes an existing tag reference with provided [name] in a [repo]sitory.
  ///
  /// The tag [name] will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({required Repository repo, required String name}) {
    bindings.delete(repoPointer: repo.pointer, tagName: name);
  }

  /// Returns a list with all the tags in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repo) {
    return bindings.list(repo.pointer);
  }

  /// Get the tagged object (commit, tree, blob, tag) of a tag.
  ///
  /// This method performs a repository lookup for the given object and returns it.
  ///
  /// Returned object should be explicitly downcasted to one of four of git object types.
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

  /// Get the id of a tag.
  Oid get id => Oid(bindings.id(_tagPointer));

  /// Returns the name of a tag.
  String get name => bindings.name(_tagPointer);

  /// Returns the message of a tag.
  String get message => bindings.message(_tagPointer);

  /// Returns the tagger (author) of a tag if there is one.
  Signature? get tagger {
    final sigPointer = bindings.tagger(_tagPointer);
    if (sigPointer != nullptr) {
      return Signature(sigPointer);
    } else {
      return null;
    }
  }

  /// Releases memory allocated for tag object.
  void free() => bindings.free(_tagPointer);
}
