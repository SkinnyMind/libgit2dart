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

  /// Initializes a new instance of [Commit] class from provided pointer to [Repository]
  /// object in memory and pointer to [Oid] object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Commit.lookup(Pointer<git_repository> repo, Pointer<git_oid> oid) {
    libgit2.git_libgit2_init();
    _commitPointer = bindings.lookup(repo, oid);
  }

  /// Pointer to memory address for allocated commit object.
  late final Pointer<git_commit> _commitPointer;

  /// Creates new commit in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required String message,
    required Signature author,
    required Signature commiter,
    required String treeSHA,
    required List<String> parentsSHA,
    String? updateRef,
    String? messageEncoding,
  }) {
    libgit2.git_libgit2_init();

    final parentCount = parentsSHA.length;
    late final Tree tree;

    if (treeSHA.length == 40) {
      final treeOid = Oid.fromSHA(treeSHA);
      tree = Tree.lookup(
        repo.pointer,
        treeOid.pointer,
      );
    } else {
      final odb = repo.odb;
      final treeOid = Oid.fromShortSHA(treeSHA, odb);
      tree = Tree.lookup(
        repo.pointer,
        treeOid.pointer,
      );
      odb.free();
    }

    final result = Oid(bindings.create(
      repo.pointer,
      updateRef,
      author.pointer,
      commiter.pointer,
      messageEncoding,
      message,
      tree.pointer,
      parentCount,
      parentsSHA,
    ));

    tree.free();
    libgit2.git_libgit2_init();

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
  List<Commit> get parents {
    var parents = <Commit>[];
    final parentCount = bindings.parentCount(_commitPointer);

    for (var i = 0; i < parentCount; i++) {
      final parentOid = bindings.parentId(_commitPointer, i);

      if (parentOid != nullptr) {
        final owner = bindings.owner(_commitPointer);
        final commit = bindings.lookup(owner, parentOid);
        parents.add(Commit(commit));
      }
    }

    return parents;
  }

  /// Get the id of the tree pointed to by a commit.
  Oid get tree => Oid(bindings.tree(_commitPointer));

  /// Releases memory allocated for commit object.
  void free() {
    bindings.free(_commitPointer);
    libgit2.git_libgit2_shutdown();
  }
}
