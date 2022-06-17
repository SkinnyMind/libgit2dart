import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Create an in-memory index object.
///
/// This index object cannot be read/written to the filesystem, but may be
/// used to perform in-memory index operations.
///
/// The returned index must be freed with [free].
Pointer<git_index> newInMemory() {
  final out = calloc<Pointer<git_index>>();
  libgit2.git_index_new(out);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Read index capabilities flags.
int capabilities(Pointer<git_index> index) => libgit2.git_index_caps(index);

/// Set index capabilities flags.
///
/// If you pass [GitIndexCapability.fromOwner] for the caps, then capabilities
/// will be read from the config of the owner object, looking at
/// core.ignorecase, core.filemode, core.symlinks.
///
/// Throws a [LibGit2Error] if error occured.
void setCapabilities({
  required Pointer<git_index> indexPointer,
  required int caps,
}) {
  final error = libgit2.git_index_set_caps(indexPointer, caps);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the full path to the index file on disk.
String path(Pointer<git_index> index) {
  return libgit2.git_index_path(index).toDartString();
}

/// Update the contents of an existing index object in memory by reading from
/// the hard disk.
///
/// If [force] is true, this performs a "hard" read that discards in-memory
/// changes and always reloads the on-disk index data. If there is no on-disk
/// version, the index will be cleared.
///
/// If [force] is false, this does a "soft" read that reloads the index data
/// from disk only if it has changed since the last time it was loaded. Purely
/// in-memory index data will be untouched. Be aware: if there are changes on
/// disk, unwritten in-memory changes are discarded.
void read({required Pointer<git_index> indexPointer, required bool force}) {
  final forceC = force == true ? 1 : 0;
  libgit2.git_index_read(indexPointer, forceC);
}

/// Read a tree into the index file with stats.
///
/// The current index contents will be replaced by the specified tree.
void readTree({
  required Pointer<git_index> indexPointer,
  required Pointer<git_tree> treePointer,
}) {
  libgit2.git_index_read_tree(indexPointer, treePointer);
}

/// Write the index as a tree.
///
/// This method will scan the index and write a representation of its current
/// state back to disk; it recursively creates tree objects for each of the
/// subtrees stored in the index, but only returns the OID of the root tree.
/// This is the OID that can be used e.g. to create a commit.
///
/// The index instance cannot be bare, and needs to be associated to an
/// existing repository.
///
/// The index must not contain any file in conflict.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> writeTree(Pointer<git_index> index) {
  final out = calloc<git_oid>();
  final error = libgit2.git_index_write_tree(out, index);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Write the index as a tree to the given repository.
///
/// This method will do the same as [writeTree], but letting the user choose
/// the repository where the tree will be written.
///
/// The index must not contain any file in conflict.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> writeTreeTo({
  required Pointer<git_index> indexPointer,
  required Pointer<git_repository> repoPointer,
}) {
  final out = calloc<git_oid>();
  final error = libgit2.git_index_write_tree_to(out, indexPointer, repoPointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Find the first position of any entries which point to given path in the Git
/// index.
bool find({required Pointer<git_index> indexPointer, required String path}) {
  final pathC = path.toChar();
  final result = libgit2.git_index_find(nullptr, indexPointer, pathC);

  calloc.free(pathC);

  return result != git_error_code.GIT_ENOTFOUND || false;
}

/// Get the count of entries currently in the index.
int entryCount(Pointer<git_index> index) => libgit2.git_index_entrycount(index);

/// Get a pointer to one of the entries in the index based on position.
///
/// The entry is not modifiable and should not be freed.
///
/// Throws [RangeError] when provided index is outside of valid range.
Pointer<git_index_entry> getByIndex({
  required Pointer<git_index> indexPointer,
  required int position,
}) {
  final result = libgit2.git_index_get_byindex(indexPointer, position);

  if (result == nullptr) {
    throw RangeError('Out of bounds');
  } else {
    return result;
  }
}

/// Get a pointer to one of the entries in the index based on path.
///
/// The entry is not modifiable and should not be freed.
///
/// Throws [ArgumentError] if nothing found for provided path.
Pointer<git_index_entry> getByPath({
  required Pointer<git_index> indexPointer,
  required String path,
  required int stage,
}) {
  final pathC = path.toChar();
  final result = libgit2.git_index_get_bypath(indexPointer, pathC, stage);

  calloc.free(pathC);

  if (result == nullptr) {
    throw ArgumentError.value('$path was not found');
  } else {
    return result;
  }
}

/// Return the stage number from a git index entry.
int entryStage(Pointer<git_index_entry> entry) =>
    libgit2.git_index_entry_stage(entry);

/// Clear the contents (all the entries) of an index object.
///
/// This clears the index object in memory; changes must be explicitly written
/// to disk for them to take effect persistently.
///
/// Throws a [LibGit2Error] if error occured.
void clear(Pointer<git_index> index) {
  final error = libgit2.git_index_clear(index);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add or update an index entry from an in-memory struct.
///
/// If a previous index entry exists that has the same path and stage as the
/// given `sourceEntry`, it will be replaced. Otherwise, the `sourceEntry` will
/// be added.
///
/// Throws a [LibGit2Error] if error occured.
void add({
  required Pointer<git_index> indexPointer,
  required Pointer<git_index_entry> sourceEntryPointer,
}) {
  final error = libgit2.git_index_add(indexPointer, sourceEntryPointer);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add or update an index entry from a file on disk.
///
/// The file [path] must be relative to the repository's working folder and must
/// be readable.
///
/// This method will fail in bare index instances.
///
/// This forces the file to be added to the index, not looking at gitignore
/// rules.
///
/// If this file currently is the result of a merge conflict, this file will no
/// longer be marked as conflicting. The data about the conflict will be moved
/// to the "resolve undo" (REUC) section.
///
/// Throws a [LibGit2Error] if error occured.
void addByPath({
  required Pointer<git_index> indexPointer,
  required String path,
}) {
  final pathC = path.toChar();
  final error = libgit2.git_index_add_bypath(indexPointer, pathC);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add or update an index entry from a buffer in memory.
///
/// This method will create a blob in the repository that owns the index and
/// then add the index entry to the index. The path of the entry represents the
/// position of the blob relative to the repository's root folder.
///
/// If a previous index entry exists that has the same path as the given
/// 'entry', it will be replaced. Otherwise, the 'entry' will be added.
///
/// This forces the file to be added to the index, not looking at gitignore
/// rules.
///
/// If this file currently is the result of a merge conflict, this file will no
/// longer be marked as conflicting. The data about the conflict will be moved
/// to the "resolve undo" (REUC) section.
///
/// Throws a [LibGit2Error] if error occured.
void addFromBuffer({
  required Pointer<git_index> indexPointer,
  required Pointer<git_index_entry> entryPointer,
  required String buffer,
}) {
  final bufferC = buffer.toChar();
  final error = libgit2.git_index_add_from_buffer(
    indexPointer,
    entryPointer,
    bufferC.cast(),
    buffer.length,
  );

  calloc.free(bufferC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add or update index entries matching files in the working directory.
///
/// This method will fail in bare index instances.
///
/// The [pathspec] is a list of file names or shell glob patterns that will be
/// matched against files in the repository's working directory. Each file that
/// matches will be added to the index (either updating an existing entry or
/// adding a new entry).
///
/// Throws a [LibGit2Error] if error occured.
void addAll({
  required Pointer<git_index> indexPointer,
  required List<String> pathspec,
  required int flags,
}) {
  final pathspecC = calloc<git_strarray>();
  final pathPointers = pathspec.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(pathspec.length);

  for (var i = 0; i < pathspec.length; i++) {
    strArray[i] = pathPointers[i];
  }

  pathspecC.ref.strings = strArray;
  pathspecC.ref.count = pathspec.length;

  final error = libgit2.git_index_add_all(
    indexPointer,
    pathspecC,
    flags,
    nullptr,
    nullptr,
  );

  calloc.free(pathspecC);
  for (final p in pathPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Update all index entries to match the working directory.
///
/// This method will fail in bare index instances.
///
/// This scans the existing index entries and synchronizes them with the
/// working directory, deleting them if the corresponding working directory
/// file no longer exists otherwise updating the information (including adding
/// the latest version of file to the ODB if needed).
///
/// Throws a [LibGit2Error] if error occured.
void updateAll({
  required Pointer<git_index> indexPointer,
  required List<String> pathspec,
}) {
  final pathspecC = calloc<git_strarray>();
  final pathPointers = pathspec.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(pathspec.length);

  for (var i = 0; i < pathspec.length; i++) {
    strArray[i] = pathPointers[i];
  }

  pathspecC.ref.strings = strArray;
  pathspecC.ref.count = pathspec.length;

  final error = libgit2.git_index_update_all(
    indexPointer,
    pathspecC,
    nullptr,
    nullptr,
  );

  calloc.free(pathspecC);
  for (final p in pathPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Write an existing index object from memory back to disk using an atomic
/// file lock.
void write(Pointer<git_index> index) => libgit2.git_index_write(index);

/// Remove an entry from the index.
///
/// Throws a [LibGit2Error] if error occured.
void remove({
  required Pointer<git_index> indexPointer,
  required String path,
  required int stage,
}) {
  final pathC = path.toChar();
  final error = libgit2.git_index_remove(indexPointer, pathC, stage);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Remove all entries from the index under a given directory.
void removeDirectory({
  required Pointer<git_index> indexPointer,
  required String dir,
  required int stage,
}) {
  final dirC = dir.toChar();
  libgit2.git_index_remove_directory(indexPointer, dirC, stage);
  calloc.free(dirC);
}

/// Remove all matching index entries.
void removeAll({
  required Pointer<git_index> indexPointer,
  required List<String> pathspec,
}) {
  final pathspecC = calloc<git_strarray>();
  final pathPointers = pathspec.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(pathspec.length);

  for (var i = 0; i < pathspec.length; i++) {
    strArray[i] = pathPointers[i];
  }

  pathspecC.ref.strings = strArray;
  pathspecC.ref.count = pathspec.length;

  libgit2.git_index_remove_all(indexPointer, pathspecC, nullptr, nullptr);

  calloc.free(pathspecC);
  for (final p in pathPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
}

/// Determine if the index contains entries representing file conflicts.
bool hasConflicts(Pointer<git_index> index) {
  return libgit2.git_index_has_conflicts(index) == 1 || false;
}

/// Return list of conflicts in the index.
///
/// Throws a [LibGit2Error] if error occured.
List<Map<String, Pointer<git_index_entry>>> conflictList(
  Pointer<git_index> index,
) {
  final iterator = calloc<Pointer<git_index_conflict_iterator>>();
  libgit2.git_index_conflict_iterator_new(iterator, index);

  final result = <Map<String, Pointer<git_index_entry>>>[];
  var error = 0;

  while (error >= 0) {
    final ancestorOut = calloc<Pointer<git_index_entry>>();
    final ourOut = calloc<Pointer<git_index_entry>>();
    final theirOut = calloc<Pointer<git_index_entry>>();
    error = libgit2.git_index_conflict_next(
      ancestorOut,
      ourOut,
      theirOut,
      iterator.value,
    );
    if (error >= 0) {
      result.add({
        'ancestor': ancestorOut.value,
        'our': ourOut.value,
        'their': theirOut.value,
      });
    } else {
      break;
    }
    calloc.free(ancestorOut);
    calloc.free(ourOut);
    calloc.free(theirOut);
  }

  libgit2.git_index_conflict_iterator_free(iterator.value);
  return result;
}

/// Return whether the given index entry is a conflict (has a high stage entry).
/// This is simply shorthand for [entryStage] > 0.
bool entryIsConflict(Pointer<git_index_entry> entry) {
  return libgit2.git_index_entry_is_conflict(entry) == 1 || false;
}

/// Add or update index entries to represent a conflict. Any staged entries
/// that exist at the given paths will be removed.
///
/// The entries are the entries from the tree included in the merge. Any entry
/// may be null to indicate that that file was not present in the trees during
/// the merge. For example, [ancestorEntryPointer] may be null to indicate that
/// a file was added in both branches and must be resolved.
///
/// Throws a [LibGit2Error] if error occured.
void conflictAdd({
  required Pointer<git_index> indexPointer,
  Pointer<git_index_entry>? ancestorEntryPointer,
  Pointer<git_index_entry>? ourEntryPointer,
  Pointer<git_index_entry>? theirEntryPointer,
}) {
  final error = libgit2.git_index_conflict_add(
    indexPointer,
    ancestorEntryPointer ?? nullptr,
    ourEntryPointer ?? nullptr,
    theirEntryPointer ?? nullptr,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Removes the index entries that represent a conflict of a single file.
///
/// Throws a [LibGit2Error] if error occured.
void conflictRemove({
  required Pointer<git_index> indexPointer,
  required String path,
}) {
  final pathC = path.toChar();
  final error = libgit2.git_index_conflict_remove(indexPointer, pathC);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Remove all conflicts in the index (entries with a stage greater than 0).
///
/// Throws a [LibGit2Error] if error occured.
void conflictCleanup(Pointer<git_index> index) {
  final error = libgit2.git_index_conflict_cleanup(index);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Free an existing index object.
void free(Pointer<git_index> index) => libgit2.git_index_free(index);
