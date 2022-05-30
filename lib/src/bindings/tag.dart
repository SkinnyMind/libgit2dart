import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Fill a list with all the tags in the repository.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  final error = libgit2.git_tag_list(out, repo);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = <String>[
      for (var i = 0; i < out.ref.count; i++) out.ref.strings[i].toDartString()
    ];

    calloc.free(out);

    return result;
  }
}

/// Lookup a tag object from the repository. The returned tag must be freed
/// with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tag> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_tag>>();
  final error = libgit2.git_tag_lookup(out, repoPointer, oidPointer);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the tagged object of a tag.
///
/// This method performs a repository lookup for the given object and returns
/// it.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> target(Pointer<git_tag> tag) {
  final out = calloc<Pointer<git_object>>();
  final error = libgit2.git_tag_target(out, tag);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the type of a tag's tagged object.
int targetType(Pointer<git_tag> tag) => libgit2.git_tag_target_type(tag);

/// Get the OID of the tagged object of a tag.
Pointer<git_oid> targetOid(Pointer<git_tag> tag) =>
    libgit2.git_tag_target_id(tag);

/// Get the id of a tag.
Pointer<git_oid> id(Pointer<git_tag> tag) => libgit2.git_tag_id(tag);

/// Get the name of a tag.
String name(Pointer<git_tag> tag) => libgit2.git_tag_name(tag).toDartString();

/// Get the message of a tag.
String message(Pointer<git_tag> tag) {
  final result = libgit2.git_tag_message(tag);
  return result == nullptr ? '' : result.toDartString();
}

/// Get the tagger (author) of a tag. The returned signature must be freed.
Pointer<git_signature> tagger(Pointer<git_tag> tag) =>
    libgit2.git_tag_tagger(tag);

/// Create a new annotated tag in the repository from an object.
///
/// A new reference will also be created pointing to this tag object. If force
/// is true and a reference already exists with the given name, it'll be
/// replaced.
///
/// The message will not be cleaned up.
///
/// The tag name will be checked for validity. You must avoid the characters
/// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
/// special meaning to revparse.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> createAnnotated({
  required Pointer<git_repository> repoPointer,
  required String tagName,
  required Pointer<git_object> targetPointer,
  required Pointer<git_signature> taggerPointer,
  required String message,
  required bool force,
}) {
  final out = calloc<git_oid>();
  final tagNameC = tagName.toChar();
  final messageC = message.toChar();
  final error = libgit2.git_tag_create(
    out,
    repoPointer,
    tagNameC,
    targetPointer,
    taggerPointer,
    messageC,
    force ? 1 : 0,
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

/// Create a new lightweight tag pointing at a target object.
///
/// A new direct reference will be created pointing to this target object. If
/// force is true and a reference already exists with the given name, it'll be
/// replaced.
///
/// The tag name will be checked for validity. See [createAnnotated] for rules
/// about valid names.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> createLightweight({
  required Pointer<git_repository> repoPointer,
  required String tagName,
  required Pointer<git_object> targetPointer,
  required bool force,
}) {
  final out = calloc<git_oid>();
  final tagNameC = tagName.toChar();
  final error = libgit2.git_tag_create_lightweight(
    out,
    repoPointer,
    tagNameC,
    targetPointer,
    force ? 1 : 0,
  );

  calloc.free(tagNameC);

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
  final tagNameC = tagName.toChar();
  final error = libgit2.git_tag_delete(repoPointer, tagNameC);

  calloc.free(tagNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Close an open tag to release memory.
void free(Pointer<git_tag> tag) => libgit2.git_tag_free(tag);
