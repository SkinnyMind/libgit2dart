import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libgit2_bindings.dart';
import 'commit.dart' as commit_bindings;
import '../error.dart';
import '../util.dart';

/// Allocate a new revision walker to iterate through a repo.
///
/// This revision walker uses a custom memory pool and an internal commit cache,
/// so it is relatively expensive to allocate.
///
/// For maximum performance, this revision walker should be reused for different walks.
///
/// This revision walker is not thread safe: it may only be used to walk a repository
/// on a single thread; however, it is possible to have several revision walkers in several
/// different threads walking the same repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_revwalk> create(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_revwalk>>();
  final error = libgit2.git_revwalk_new(out, repo);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Change the sorting mode when iterating through the repository's contents.
///
/// Changing the sorting mode resets the walker.
///
/// Throws a [LibGit2Error] if error occured.
void sorting({
  required Pointer<git_revwalk> walkerPointer,
  required int sortMode,
}) {
  final error = libgit2.git_revwalk_sorting(walkerPointer, sortMode);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add a new root for the traversal.
///
/// The pushed commit will be marked as one of the roots from which to start the walk.
/// This commit may not be walked if it or a child is hidden.
///
/// At least one commit must be pushed onto the walker before a walk can be started.
///
/// The given id must belong to a committish on the walked repository.
///
/// Throws a [LibGit2Error] if error occured.
void push({
  required Pointer<git_revwalk> walkerPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final error = libgit2.git_revwalk_push(walkerPointer, oidPointer);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the list of commits from the revision walk.
///
/// The initial call to this method is not blocking when iterating through a repo
/// with a time-sorting mode.
///
/// Iterating with Topological or inverted modes makes the initial call blocking to
/// preprocess the commit list, but this block should be mostly unnoticeable on most
/// repositories (topological preprocessing times at 0.3s on the git.git repo).
///
/// The revision walker is reset when the walk is over.
List<Pointer<git_commit>> walk({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_revwalk> walkerPointer,
}) {
  var result = <Pointer<git_commit>>[];
  var error = 0;

  while (error == 0) {
    final oid = calloc<git_oid>();
    error = libgit2.git_revwalk_next(oid, walkerPointer);
    if (error == 0) {
      final commit = commit_bindings.lookup(
        repoPointer: repoPointer,
        oidPointer: oid,
      );
      result.add(commit);
      calloc.free(oid);
    } else {
      break;
    }
  }

  return result;
}

/// Mark a commit (and its ancestors) uninteresting for the output.
///
/// The given id must belong to a committish on the walked repository.
///
/// The resolved commit and all its parents will be hidden from the output on the revision walk.
///
/// Throws a [LibGit2Error] if error occured.
void hide({
  required Pointer<git_revwalk> walkerPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final error = libgit2.git_revwalk_hide(walkerPointer, oidPointer);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Reset the revision walker for reuse.
///
/// This will clear all the pushed and hidden commits, and leave the walker in a blank state
/// (just like at creation) ready to receive new commit pushes and start a new walk.
///
/// The revision walk is automatically reset when a walk is over.
void reset(Pointer<git_revwalk> walker) => libgit2.git_revwalk_reset(walker);

/// Simplify the history by first-parent.
///
/// No parents other than the first for each commit will be enqueued.
///
/// Throws a [LibGit2Error] if error occured.
void simplifyFirstParent(Pointer<git_revwalk> walker) {
  final error = libgit2.git_revwalk_simplify_first_parent(walker);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Return the repository on which this walker is operating.
Pointer<git_repository> repository(Pointer<git_revwalk> walker) {
  return libgit2.git_revwalk_repository(walker);
}

/// Free a revision walker previously allocated.
void free(Pointer<git_revwalk> walk) => libgit2.git_revwalk_free(walk);
