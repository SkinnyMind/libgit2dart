import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Allocate a new mailmap object.
///
/// This object is empty, so you'll have to add a mailmap file before you can
/// do anything with it. The mailmap must be freed with `free()`.
Pointer<git_mailmap> init() {
  final out = calloc<Pointer<git_mailmap>>();
  libgit2.git_mailmap_new(out);

  return out.value;
}

/// Create a new mailmap instance containing a single mailmap file.
Pointer<git_mailmap> fromBuffer(String buffer) {
  final out = calloc<Pointer<git_mailmap>>();
  final bufferC = buffer.toNativeUtf8().cast<Int8>();

  libgit2.git_mailmap_from_buffer(out, bufferC, buffer.length);

  calloc.free(bufferC);

  return out.value;
}

/// Create a new mailmap instance from a repository, loading mailmap files based
/// on the repository's configuration.
///
/// Mailmaps are loaded in the following order:
///
/// 1. `.mailmap` in the root of the repository's working directory, if present.
/// 2. The blob object identified by the `mailmap.blob` config entry, if set.
///   NOTE: `mailmap.blob` defaults to `HEAD:.mailmap` in bare repositories
/// 3. The path in the `mailmap.file` config entry, if set.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_mailmap> fromRepository(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_mailmap>>();
  final error = libgit2.git_mailmap_from_repository(out, repo);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Resolve a name and email to the corresponding real name and email.
List<String> resolve({
  required Pointer<git_mailmap> mailmapPointer,
  required String name,
  required String email,
}) {
  final outRealName = calloc<Pointer<Int8>>();
  final outRealEmail = calloc<Pointer<Int8>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final emailC = email.toNativeUtf8().cast<Int8>();
  libgit2.git_mailmap_resolve(
    outRealName,
    outRealEmail,
    mailmapPointer,
    nameC,
    emailC,
  );

  final realName = outRealName.value.cast<Utf8>().toDartString();
  final realEmail = outRealEmail.value.cast<Utf8>().toDartString();
  calloc.free(outRealName);
  calloc.free(outRealEmail);
  calloc.free(nameC);
  calloc.free(emailC);

  return [realName, realEmail];
}

/// Resolve a signature to use real names and emails with a mailmap.
Pointer<git_signature> resolveSignature({
  required Pointer<git_mailmap> mailmapPointer,
  required Pointer<git_signature> signaturePointer,
}) {
  final out = calloc<Pointer<git_signature>>();
  libgit2.git_mailmap_resolve_signature(out, mailmapPointer, signaturePointer);

  return out.value;
}

/// Add a single entry to the given mailmap object. If the entry already exists,
/// it will be replaced with the new entry.
///
/// Throws a [LibGit2Error] if error occured.
void addEntry({
  required Pointer<git_mailmap> mailmapPointer,
  String? realName,
  String? realEmail,
  String? replaceName,
  required String replaceEmail,
}) {
  final realNameC = realName?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final realEmailC = realEmail?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final replaceNameC = replaceName?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final replaceEmailC = replaceEmail.toNativeUtf8().cast<Int8>();

  libgit2.git_mailmap_add_entry(
    mailmapPointer,
    realNameC,
    realEmailC,
    replaceNameC,
    replaceEmailC,
  );

  calloc.free(realNameC);
  calloc.free(realEmailC);
  calloc.free(replaceNameC);
  calloc.free(replaceEmailC);
}

/// Free the mailmap and its associated memory.
void free(Pointer<git_mailmap> mm) => libgit2.git_mailmap_free(mm);
