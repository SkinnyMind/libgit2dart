import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/commit.dart' as bindings;
import 'repository.dart';
import 'oid.dart';
import 'signature.dart';
import 'tree.dart';
import 'util.dart';

class Commit {
  /// Initializes a new instance of [Commit] class from provided pointer to
  /// commit object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Commit(this._commitPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Commit] class from provided [Repository] object
  /// and [sha] hex string.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Commit.lookup(Repository repo, String sha) {
    final oid = Oid.fromSHA(repo, sha);
    _commitPointer = bindings.lookup(repo.pointer, oid.pointer);
  }

  late final Pointer<git_commit> _commitPointer;

  /// Pointer to memory address for allocated commit object.
  Pointer<git_commit> get pointer => _commitPointer;

  /// Creates new commit in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required String message,
    required Signature author,
    required Signature commiter,
    required String treeSHA,
    required List<String> parents,
    String? updateRef,
    String? messageEncoding,
  }) {
    final tree = Tree.lookup(repo, treeSHA);

    final result = Oid(bindings.create(
      repo.pointer,
      updateRef,
      author.pointer,
      commiter.pointer,
      messageEncoding,
      message,
      tree.pointer,
      parents.length,
      parents,
    ));

    tree.free();

    return result;
  }

  /// Returns the encoding for the message of a commit, as a string
  /// representing a standard encoding name.
  String get messageEncoding => bindings.messageEncoding(_commitPointer);

  /// Returns the full message of a commit.
  ///
  /// The returned message will be slightly prettified by removing any potential leading newlines.
  String get message => bindings.message(_commitPointer);

  /// Returns the id of a commit.
  Oid get id => Oid(bindings.id(_commitPointer));

  /// Returns the commit time (i.e. committer time) of a commit.
  int get time => bindings.time(_commitPointer);

  /// Returns the committer of a commit.
  Signature get committer => Signature(bindings.committer(_commitPointer));

  /// Returns the author of a commit.
  Signature get author => Signature(bindings.author(_commitPointer));

  /// Returns list of parent commits.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Oid> get parents {
    var parents = <Oid>[];
    final parentCount = bindings.parentCount(_commitPointer);

    for (var i = 0; i < parentCount; i++) {
      final parentOid = bindings.parentId(_commitPointer, i);
      parents.add(Oid(parentOid));
    }

    return parents;
  }

  /// Get the id of the tree pointed to by a commit.
  Oid get tree => Oid(bindings.tree(_commitPointer));

  /// Releases memory allocated for commit object.
  void free() => bindings.free(_commitPointer);

  @override
  String toString() => 'Commit{id: $id}';
}
