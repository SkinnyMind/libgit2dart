import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Fill a list with all the tags in the repository.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  final error = libgit2.git_tag_list(out, repo);

  var result = <String>[];

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    for (var i = 0; i < out.ref.count; i++) {
      result.add(out.ref.strings[i].cast<Utf8>().toDartString());
    }
    calloc.free(out);
    return result;
  }
}

/// Lookup a tag object from the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tag> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_tag>>();
  final error = libgit2.git_tag_lookup(out, repoPointer, oidPointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the tagged object of a tag.
///
/// This method performs a repository lookup for the given object and returns it.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> target(Pointer<git_tag> tag) {
  final out = calloc<Pointer<git_object>>();
  final error = libgit2.git_tag_target(out, tag);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the type of a tag's tagged object.
int targetType(Pointer<git_tag> tag) => libgit2.git_tag_target_type(tag);

/// Get the id of a tag.
Pointer<git_oid> id(Pointer<git_tag> tag) => libgit2.git_tag_id(tag);

/// Get the name of a tag.
String name(Pointer<git_tag> tag) =>
    libgit2.git_tag_name(tag).cast<Utf8>().toDartString();

/// Get the message of a tag.
String message(Pointer<git_tag> tag) =>
    libgit2.git_tag_message(tag).cast<Utf8>().toDartString();

/// Get the tagger (author) of a tag.
Pointer<git_signature> tagger(Pointer<git_tag> tag) =>
    libgit2.git_tag_tagger(tag);

/// Create a new tag in the repository from an object.
///
/// A new reference will also be created pointing to this tag object. If force is true
/// and a reference already exists with the given name, it'll be replaced.
///
/// The message will not be cleaned up.
///
/// The tag name will be checked for validity. You must avoid the characters
/// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
/// special meaning to revparse.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create({
  required Pointer<git_repository> repoPointer,
  required String tagName,
  required Pointer<git_object> targetPointer,
  required Pointer<git_signature> taggerPointer,
  required String message,
  required bool force,
}) {
  final out = calloc<git_oid>();
  final tagNameC = tagName.toNativeUtf8().cast<Int8>();
  final messageC = message.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_tag_create(
    out,
    repoPointer,
    tagNameC,
    targetPointer,
    taggerPointer,
    messageC,
    forceC,
  );

  calloc.free(tagNameC);
  calloc.free(messageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Delete an existing tag reference.
///
/// The tag name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_repository> repoPointer,
  required String tagName,
}) {
  final tagNameC = tagName.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_tag_delete(repoPointer, tagNameC);

  calloc.free(tagNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Close an open tag to release memory.
void free(Pointer<git_tag> tag) => libgit2.git_tag_free(tag);
