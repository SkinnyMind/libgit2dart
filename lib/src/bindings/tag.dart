import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Lookup a tag object from the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tag> lookup(Pointer<git_repository> repo, Pointer<git_oid> id) {
  final out = calloc<Pointer<git_tag>>();
  final error = libgit2.git_tag_lookup(out, repo, id);

  if (error < 0) {
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
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

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
Pointer<git_oid> create(
  Pointer<git_repository> repo,
  String tagName,
  Pointer<git_object> target,
  Pointer<git_signature> tagger,
  String message,
  bool force,
) {
  final out = calloc<git_oid>();
  final tagNameC = tagName.toNativeUtf8().cast<Int8>();
  final messageC = message.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_tag_create(
    out,
    repo,
    tagNameC,
    target,
    tagger,
    messageC,
    forceC,
  );

  calloc.free(tagNameC);
  calloc.free(messageC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Close an open tag to release memory.
void free(Pointer<git_tag> tag) => libgit2.git_tag_free(tag);
