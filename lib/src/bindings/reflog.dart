import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Read the reflog for the given reference. The returned reflog must be
/// freed with [free].
///
/// If there is no reflog file for the given reference yet, an empty reflog
/// object will be returned.
Pointer<git_reflog> read({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_reflog>>();
  final nameC = name.toChar();
  libgit2.git_reflog_read(out, repoPointer, nameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);

  return result;
}

/// Write an existing in-memory reflog object back to disk using an atomic file
/// lock.
///
/// Throws a [LibGit2Error] if error occured.
void write(Pointer<git_reflog> reflog) {
  final error = libgit2.git_reflog_write(reflog);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Delete the reflog for the given reference.
void delete({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final nameC = name.toChar();
  libgit2.git_reflog_delete(repoPointer, nameC);
  calloc.free(nameC);
}

/// Rename a reflog.
///
/// The reflog to be renamed is expected to already exist.
///
/// The new name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
void rename({
  required Pointer<git_repository> repoPointer,
  required String oldName,
  required String newName,
}) {
  final oldNameC = oldName.toChar();
  final newNameC = newName.toChar();
  final error = libgit2.git_reflog_rename(repoPointer, oldNameC, newNameC);

  calloc.free(oldNameC);
  calloc.free(newNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add a new entry to the in-memory reflog.
///
/// Throws a [LibGit2Error] if error occured.
void add({
  required Pointer<git_reflog> reflogPointer,
  required Pointer<git_oid> oidPointer,
  required Pointer<git_signature> committerPointer,
  required String message,
}) {
  final messageC = message.isEmpty ? nullptr : message.toChar();

  final error = libgit2.git_reflog_append(
    reflogPointer,
    oidPointer,
    committerPointer,
    messageC,
  );

  calloc.free(messageC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Remove an entry from the reflog by its index.
///
/// Throws a [LibGit2Error] if error occured.
void remove({
  required Pointer<git_reflog> reflogPointer,
  required int index,
}) {
  final error = libgit2.git_reflog_drop(reflogPointer, index, 1);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the number of log entries in a reflog.
int entryCount(Pointer<git_reflog> reflog) =>
    libgit2.git_reflog_entrycount(reflog);

/// Lookup an entry by its index.
///
/// Requesting the reflog entry with an index of 0 (zero) will return
/// the most recently created entry.
Pointer<git_reflog_entry> getByIndex({
  required Pointer<git_reflog> reflogPointer,
  required int index,
}) {
  return libgit2.git_reflog_entry_byindex(reflogPointer, index);
}

/// Get the log message.
String entryMessage(Pointer<git_reflog_entry> entry) {
  final result = libgit2.git_reflog_entry_message(entry);
  return result == nullptr ? '' : result.toDartString();
}

/// Get the committer of this entry. The returned signature must be freed.
Pointer<git_signature> entryCommiter(Pointer<git_reflog_entry> entry) {
  return libgit2.git_reflog_entry_committer(entry);
}

/// Get the new oid.
Pointer<git_oid> entryOidNew(Pointer<git_reflog_entry> entry) {
  return libgit2.git_reflog_entry_id_new(entry);
}

/// Get the old oid.
Pointer<git_oid> entryOidOld(Pointer<git_reflog_entry> entry) {
  return libgit2.git_reflog_entry_id_old(entry);
}

/// Free the reflog.
void free(Pointer<git_reflog> reflog) => libgit2.git_reflog_free(reflog);
