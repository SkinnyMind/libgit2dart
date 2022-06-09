import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/commit.dart' as commit_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Allocate a new revision walker to iterate through a repo. The returned
/// revision walker must be freed with [free].
///
/// This revision walker uses a custom memory pool and an internal commit cache,
/// so it is relatively expensive to allocate.
///
/// For maximum performance, this revision walker should be reused for
/// different walks.
///
/// This revision walker is not thread safe: it may only be used to walk a
/// repository on a single thread; however, it is possible to have several
/// revision walkers in several different threads walking the same repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_revwalk> create(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_revwalk>>();
  final error = libgit2.git_revwalk_new(out, repo);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Change the sorting mode when iterating through the repository's contents.
///
/// Changing the sorting mode resets the walker.
void sorting({
  required Pointer<git_revwalk> walkerPointer,
  required int sortMode,
}) {
  libgit2.git_revwalk_sorting(walkerPointer, sortMode);
}

/// Add a new root for the traversal.
///
/// The pushed commit will be marked as one of the roots from which to start
/// the walk. This commit may not be walked if it or a child is hidden.
///
/// At least one commit must be pushed onto the walker before a walk can be
/// started.
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

/// Push matching references.
///
/// The OIDs pointed to by the references that match the given glob pattern
/// will be pushed to the revision walker.
///
/// A leading 'refs/' is implied if not present as well as a trailing '/\*'
/// if the glob lacks '?', '*' or '['.
///
/// Any references matching this glob which do not point to a committish will
/// be ignored.
void pushGlob({
  required Pointer<git_revwalk> walkerPointer,
  required String glob,
}) {
  final globC = glob.toChar();
  libgit2.git_revwalk_push_glob(walkerPointer, globC);
  calloc.free(globC);
}

/// Push the repository's HEAD.
void pushHead(Pointer<git_revwalk> walker) =>
    libgit2.git_revwalk_push_head(walker);

/// Push the OID pointed to by a reference.
///
/// The reference must point to a committish.
///
/// Throws a [LibGit2Error] if error occured.
void pushRef({
  required Pointer<git_revwalk> walkerPointer,
  required String refName,
}) {
  final refNameC = refName.toChar();
  final error = libgit2.git_revwalk_push_ref(walkerPointer, refNameC);

  calloc.free(refNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Push and hide the respective endpoints of the given range.
///
/// The range should be of the form `..` The left-hand commit will be hidden
/// and the right-hand commit pushed.
///
/// Throws a [LibGit2Error] if error occured.
void pushRange({
  required Pointer<git_revwalk> walkerPointer,
  required String range,
}) {
  final rangeC = range.toChar();
  final error = libgit2.git_revwalk_push_range(walkerPointer, rangeC);

  calloc.free(rangeC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the list of commits from the revision walk. The returned commits must
/// be freed.
///
/// The initial call to this method is not blocking when iterating through a
/// repo with a time-sorting mode.
///
/// Iterating with Topological or inverted modes makes the initial call
/// blocking to preprocess the commit list, but this block should be mostly
/// unnoticeable on most repositories (topological preprocessing times at 0.3s
/// on the git.git repo).
///
/// The revision walker is reset when the walk is over.
List<Pointer<git_commit>> walk({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_revwalk> walkerPointer,
  required int limit,
}) {
  final result = <Pointer<git_commit>>[];
  var error = 0;

  void next() {
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
      calloc.free(oid);
      return;
    }
  }

  if (limit == 0) {
    while (error == 0) {
      next();
    }
  } else {
    for (var i = 0; i < limit; i++) {
      next();
    }
  }

  return result;
}

/// Mark a commit (and its ancestors) uninteresting for the output.
///
/// The given id must belong to a committish on the walked repository.
///
/// The resolved commit and all its parents will be hidden from the output on
/// the revision walk.
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

/// Hide matching references.
///
/// The OIDs pointed to by the references that match the given glob pattern and
/// their ancestors will be hidden from the output on the revision walk.
///
/// A leading 'refs/' is implied if not present as well as a trailing '/\*' if
/// the glob lacks '?', '*' or '['.
///
/// Any references matching this glob which do not point to a committish will
/// be ignored.
void hideGlob({
  required Pointer<git_revwalk> walkerPointer,
  required String glob,
}) {
  final globC = glob.toChar();
  libgit2.git_revwalk_hide_glob(walkerPointer, globC);
  calloc.free(globC);
}

/// Hide the repository's HEAD.
void hideHead(Pointer<git_revwalk> walker) =>
    libgit2.git_revwalk_hide_head(walker);

/// Hide the OID pointed to by a reference.
///
/// The reference must point to a committish.
///
/// Throws a [LibGit2Error] if error occured.
void hideRef({
  required Pointer<git_revwalk> walkerPointer,
  required String refName,
}) {
  final refNameC = refName.toChar();
  final error = libgit2.git_revwalk_hide_ref(walkerPointer, refNameC);

  calloc.free(refNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Reset the revision walker for reuse.
///
/// This will clear all the pushed and hidden commits, and leave the walker in
/// a blank state (just like at creation) ready to receive new commit pushes
/// and start a new walk.
///
/// The revision walk is automatically reset when a walk is over.
void reset(Pointer<git_revwalk> walker) => libgit2.git_revwalk_reset(walker);

/// Simplify the history by first-parent.
///
/// No parents other than the first for each commit will be enqueued.
void simplifyFirstParent(Pointer<git_revwalk> walker) {
  libgit2.git_revwalk_simplify_first_parent(walker);
}

/// Return the repository on which this walker is operating.
Pointer<git_repository> repository(Pointer<git_revwalk> walker) {
  return libgit2.git_revwalk_repository(walker);
}

/// Free a revision walker previously allocated.
void free(Pointer<git_revwalk> walk) => libgit2.git_revwalk_free(walk);
