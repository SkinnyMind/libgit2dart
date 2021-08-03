import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Get the type of a reference.
int referenceType(Pointer<git_reference> ref) =>
    libgit2.git_reference_type(ref);

/// Get the OID pointed to by a direct reference.
///
/// Only available if the reference is direct (i.e. an object id reference, not a symbolic one).
Pointer<git_oid>? target(Pointer<git_reference> ref) =>
    libgit2.git_reference_target(ref);

/// Lookup a reference by name in a repository.
///
/// The returned reference must be freed by the user.
///
/// The name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> lookup(Pointer<git_repository> repo, String name) {
  final out = calloc<Pointer<git_reference>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_reference_lookup(out, repo, nameC);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the full name of a reference.
String name(Pointer<git_reference> ref) {
  var result = calloc<Int8>();
  result = libgit2.git_reference_name(ref);

  return result.cast<Utf8>().toDartString();
}

/// Fill a list with all the references that can be found in a repository.
///
/// The string array will be filled with the names of all references;
/// these values are owned by the user and should be free'd manually when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  var array = calloc<git_strarray>();
  final error = libgit2.git_reference_list(array, repo);
  var result = <String>[];

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    for (var i = 0; i < array.ref.count; i++) {
      result.add(
          array.ref.strings.elementAt(i).value.cast<Utf8>().toDartString());
    }
  }

  calloc.free(array);
  return result;
}

/// Check if a reflog exists for the specified reference.
///
/// Throws a [LibGit2Error] if error occured.
bool hasLog(Pointer<git_repository> repo, String name) {
  final refname = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_reference_has_log(repo, refname);
  calloc.free(refname);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 ? true : false;
  }
}

/// Check if a reference is a local branch.
bool isBranch(Pointer<git_reference> ref) {
  final result = libgit2.git_reference_is_branch(ref);
  return result == 1 ? true : false;
}

/// Check if a reference is a note.
bool isNote(Pointer<git_reference> ref) {
  final result = libgit2.git_reference_is_note(ref);
  return result == 1 ? true : false;
}

/// Check if a reference is a remote tracking branch.
bool isRemote(Pointer<git_reference> ref) {
  final result = libgit2.git_reference_is_remote(ref);
  return result == 1 ? true : false;
}

/// Check if a reference is a tag.
bool isTag(Pointer<git_reference> ref) {
  final result = libgit2.git_reference_is_tag(ref);
  return result == 1 ? true : false;
}

/// Ensure the reference name is well-formed.
///
/// Valid reference names must follow one of two patterns:
///
/// Top-level names must contain only capital letters and underscores,
/// and must begin and end with a letter. (e.g. "HEAD", "ORIG_HEAD").
/// Names prefixed with "refs/" can be almost anything. You must avoid
/// the characters '~', '^', ':', '\', '?', '[', and '*', and the sequences ".."
/// and "@{" which have special meaning to revparse.
bool isValidName(String name) {
  final refname = name.toNativeUtf8().cast<Int8>();
  final result = libgit2.git_reference_is_valid_name(refname);
  calloc.free(refname);
  return result == 1 ? true : false;
}
