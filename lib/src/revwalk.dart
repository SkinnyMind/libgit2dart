import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/revwalk.dart' as bindings;
import 'package:meta/meta.dart';

class RevWalk {
  /// Initializes a new instance of the [RevWalk] class.
  RevWalk(Repository repo) {
    _revWalkPointer = bindings.create(repo.pointer);
    _finalizer.attach(this, _revWalkPointer, detach: this);
  }

  late final Pointer<git_revwalk> _revWalkPointer;

  /// Pointer to memory address for allocated [RevWalk] object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_revwalk> get pointer => _revWalkPointer;

  /// Returns the list of commits from the revision walk.
  ///
  /// [limit] is optional number of commits to walk (by default walks through
  /// all of the commits pushed onto the walker).
  ///
  /// Default sorting is reverse chronological order (default in git).
  List<Commit> walk({int limit = 0}) {
    final pointers = bindings.walk(
      repoPointer: bindings.repository(_revWalkPointer),
      walkerPointer: _revWalkPointer,
      limit: limit,
    );

    return pointers.map((e) => Commit(e)).toList();
  }

  /// Changes the sorting mode when iterating through the repository's contents
  /// to provided [sorting] combination of [GitSort] modes.
  ///
  /// Changing the sorting mode resets the walker.
  void sorting(Set<GitSort> sorting) {
    bindings.sorting(
      walkerPointer: _revWalkPointer,
      sortMode: sorting.fold(0, (acc, e) => acc | e.value),
    );
  }

  /// Adds a new root commit [oid] for the traversal.
  ///
  /// The pushed commit will be marked as one of the roots from which to start
  /// the walk. This commit may not be walked if it or a child is hidden.
  ///
  /// At least one commit must be pushed onto the walker before a walk can be
  /// started.
  ///
  /// The given [oid] must belong to a committish on the walked repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void push(Oid oid) {
    bindings.push(
      walkerPointer: _revWalkPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Adds matching references for the traversal.
  ///
  /// The OIDs pointed to by the references that match the given [glob] pattern
  /// will be pushed to the revision walker.
  ///
  /// A leading "refs/" is implied if not present as well as a trailing "/\*"
  /// if the glob lacks "?", "*" or "[".
  ///
  /// Any references matching this glob which do not point to a committish will
  /// be ignored.
  void pushGlob(String glob) {
    bindings.pushGlob(walkerPointer: _revWalkPointer, glob: glob);
  }

  /// Adds the repository's HEAD for the traversal.
  void pushHead() => bindings.pushHead(_revWalkPointer);

  /// Adds the oid pointed to by a [reference] for the traversal.
  ///
  /// The reference must point to a committish.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void pushReference(String reference) {
    bindings.pushRef(walkerPointer: _revWalkPointer, refName: reference);
  }

  /// Adds and hide the respective endpoints of the given [range] for the
  /// traversal.
  ///
  /// The range should be of the form `..` The left-hand commit will be hidden
  /// and the right-hand commit pushed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void pushRange(String range) {
    bindings.pushRange(walkerPointer: _revWalkPointer, range: range);
  }

  /// Marks a commit [oid] (and its ancestors) uninteresting for the output.
  ///
  /// The given id must belong to a committish on the walked repository.
  ///
  /// The resolved commit and all its parents will be hidden from the output on
  /// the revision walk.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void hide(Oid oid) {
    bindings.hide(
      walkerPointer: _revWalkPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Hides matching references.
  ///
  /// The OIDs pointed to by the references that match the given [glob] pattern
  /// and their ancestors will be hidden from the output on the revision walk.
  ///
  /// A leading "refs/" is implied if not present as well as a trailing "/\*" if
  /// the glob lacks "?", "*" or "[".
  ///
  /// Any references matching this glob which do not point to a committish will
  /// be ignored.
  void hideGlob(String glob) {
    bindings.hideGlob(walkerPointer: _revWalkPointer, glob: glob);
  }

  /// Hides the repository's HEAD and it's ancestors.
  void hideHead() => bindings.hideHead(_revWalkPointer);

  /// Hides the oid pointed to by a [reference].
  ///
  /// The reference must point to a committish.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void hideReference(String reference) {
    bindings.hideRef(walkerPointer: _revWalkPointer, refName: reference);
  }

  /// Resets the revision walker for reuse.
  ///
  /// This will clear all the pushed and hidden commits, and leave the walker
  /// in a blank state (just like at creation) ready to receive new commit
  /// pushes and start a new walk.
  ///
  /// The revision walk is automatically reset when a walk is over.
  void reset() => bindings.reset(_revWalkPointer);

  /// Simplify the history by first-parent.
  ///
  /// No parents other than the first for each commit will be enqueued.
  void simplifyFirstParent() => bindings.simplifyFirstParent(_revWalkPointer);

  /// Releases memory allocated for [RevWalk] object.
  void free() {
    bindings.free(_revWalkPointer);
    _finalizer.detach(this);
  }
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_revwalk>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
