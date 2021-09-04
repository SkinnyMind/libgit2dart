import 'dart:ffi';

import 'bindings/libgit2_bindings.dart';
import 'bindings/tag.dart' as bindings;
import 'bindings/object.dart' as object_bindings;
import 'commit.dart';
import 'oid.dart';
import 'repository.dart';
import 'signature.dart';
import 'git_types.dart';
import 'util.dart';

class Tag {
  /// Initializes a new instance of [Tag] class from provided pointer to
  /// tag object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Tag(this._tagPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Tag] class from provided
  /// [Repository] object and [sha] hex string.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Tag.lookup(Repository repo, String sha) {
    final oid = Oid.fromSHA(repo, sha);
    _tagPointer = bindings.lookup(repo.pointer, oid.pointer);
  }

  late final Pointer<git_tag> _tagPointer;

  /// Pointer to memory address for allocated tag object.
  Pointer<git_tag> get pointer => _tagPointer;

  /// Creates a new tag in the repository from provided Oid object.
  ///
  /// A new reference will also be created pointing to this tag object. If force is true
  /// and a reference already exists with the given name, it'll be replaced.
  ///
  /// The message will not be cleaned up.
  ///
  /// The tag name will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repository,
    required String tagName,
    required Oid target,
    required GitObject targetType,
    required Signature tagger,
    required String message,
    bool force = false,
  }) {
    final object = object_bindings.lookup(
      repository.pointer,
      target.pointer,
      targetType.value,
    );
    final result = bindings.create(
      repository.pointer,
      tagName,
      object,
      tagger.pointer,
      message,
      force,
    );

    object_bindings.free(object);
    return Oid(result);
  }

  /// Get the tagged object of a tag.
  ///
  /// This method performs a repository lookup for the given object and returns it.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Commit get target => Commit(bindings.target(_tagPointer).cast());

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
