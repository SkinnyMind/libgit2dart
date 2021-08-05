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
///
/// Throws an exception if error occured.
Pointer<git_oid> target(Pointer<git_reference> ref) {
  final result = libgit2.git_reference_target(ref);

  if (result == nullptr) {
    throw Exception('OID for reference isn\'t available');
  } else {
    return result;
  }
}

/// Resolve a symbolic reference to a direct reference.
///
/// This method iteratively peels a symbolic reference until it resolves
/// to a direct reference to an OID.
///
/// The peeled reference must be freed manually once it's no longer needed.
///
/// If a direct reference is passed as an argument, a copy of that reference is returned.
/// This copy must be manually freed too.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> resolve(Pointer<git_reference> ref) {
  final out = calloc<Pointer<git_reference>>();
  final error = libgit2.git_reference_resolve(out, ref);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

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

/// Create a new direct reference.
///
/// A direct reference (also called an object id reference) refers directly to a
/// specific object id (a.k.a. OID or SHA) in the repository. The id permanently refers to
/// the object (although the reference itself can be moved). For example, in libgit2
/// the direct ref "refs/tags/v0.17.0" refers to OID 5b9fac39d8a76b9139667c26a63e6b3f204b3977.
///
/// The direct reference will be created in the repository and written to the disk.
/// The generated reference object must be freed by the user.
///
/// Valid reference names must follow one of two patterns:
///
/// Top-level names must contain only capital letters and underscores, and must begin and end
/// with a letter. (e.g. "HEAD", "ORIG_HEAD").
/// Names prefixed with "refs/" can be almost anything. You must avoid the characters
/// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
/// special meaning to revparse.
/// This function will throw a [LibGit2Error] if a reference already exists with the given name
/// unless force is true, in which case it will be overwritten.
///
/// The message for the reflog will be ignored if the reference does not belong in the
/// standard set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
Pointer<git_reference> createDirect(
  Pointer<git_repository> repo,
  String name,
  Pointer<git_oid> oid,
  bool force,
  String logMessage,
) {
  final out = calloc<Pointer<git_reference>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final forceC = force == true ? 1 : 0;
  final logMessageC = logMessage.toNativeUtf8().cast<Int8>();
  final error =
      libgit2.git_reference_create(out, repo, nameC, oid, forceC, logMessageC);
  calloc.free(nameC);
  calloc.free(logMessageC);

  if (error < 0) {
    throw (LibGit2Error(libgit2.git_error_last()));
  } else {
    return out.value;
  }
}

/// Delete an existing reference.
///
/// This method works for both direct and symbolic references.
/// The reference will be immediately removed on disk but the memory will not be freed.
///
/// Throws a [LibGit2Error] if the reference has changed from the time it was looked up.
void delete(Pointer<git_reference> ref) {
  final error = libgit2.git_reference_delete(ref);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the repository where a reference resides.
Pointer<git_repository> owner(Pointer<git_reference> ref) {
  return libgit2.git_reference_owner(ref);
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
