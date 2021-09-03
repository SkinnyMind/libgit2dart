import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/revwalk.dart' as bindings;
import 'commit.dart';
import 'oid.dart';
import 'repository.dart';
import 'git_types.dart';

class RevWalk {
  /// Initializes a new instance of the [RevWalk] class.
  /// Should be freed with `free()` to release allocated memory.
  RevWalk(Repository repo) {
    _revWalkPointer = bindings.create(repo.pointer);
  }

  /// Pointer to memory address for allocated [RevWalk] object.
  late final Pointer<git_revwalk> _revWalkPointer;

  /// Returns the list of commits from the revision walk.
  ///
  /// Default sorting is reverse chronological order (default in git).
  List<Commit> walk() {
    final repoPointer = bindings.repository(_revWalkPointer);
    var result = <Commit>[];

    final commits = bindings.walk(repoPointer, _revWalkPointer);
    for (var commit in commits) {
      result.add(Commit(commit));
    }

    return result;
  }

  /// Changes the sorting mode when iterating through the repository's contents.
  ///
  /// Changing the sorting mode resets the walker.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void sorting(GitSort sorting) =>
      bindings.sorting(_revWalkPointer, sorting.value);

  /// Adds a new root for the traversal.
  ///
  /// The pushed commit will be marked as one of the roots from which to start the walk.
  /// This commit may not be walked if it or a child is hidden.
  ///
  /// At least one commit must be pushed onto the walker before a walk can be started.
  ///
  /// The given id must belong to a committish on the walked repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void push(Oid oid) => bindings.push(_revWalkPointer, oid.pointer);

  /// Marks a commit (and its ancestors) uninteresting for the output.
  ///
  /// The given id must belong to a committish on the walked repository.
  ///
  /// The resolved commit and all its parents will be hidden from the output on the revision walk.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void hide(Oid oid) => bindings.hide(_revWalkPointer, oid.pointer);

  /// Resets the revision walker for reuse.
  ///
  /// This will clear all the pushed and hidden commits, and leave the walker in a blank state
  /// (just like at creation) ready to receive new commit pushes and start a new walk.
  ///
  /// The revision walk is automatically reset when a walk is over.
  void reset() => bindings.reset(_revWalkPointer);

  /// Simplify the history by first-parent.
  ///
  /// No parents other than the first for each commit will be enqueued.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void simplifyFirstParent() => bindings.simplifyFirstParent(_revWalkPointer);

  /// Releases memory allocated for [RevWalk] object.
  void free() => bindings.free(_revWalkPointer);
}
