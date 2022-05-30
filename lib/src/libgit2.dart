import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

class Libgit2 {
  Libgit2._(); // coverage:ignore-line

  /// Libgit2 version number.
  static String get version {
    libgit2.git_libgit2_init();

    final major = calloc<Int>();
    final minor = calloc<Int>();
    final rev = calloc<Int>();
    libgit2.git_libgit2_version(major, minor, rev);

    final version = '${major.value}.${minor.value}.${rev.value}';

    calloc.free(major);
    calloc.free(minor);
    calloc.free(rev);

    return version;
  }

  /// Options libgit2 was compiled with.
  static Set<GitFeature> get features {
    libgit2.git_libgit2_init();
    final featuresInt = libgit2.git_libgit2_features();
    return GitFeature.values
        .where((e) => featuresInt & e.value == e.value)
        .toSet();
  }

  /// Maximum mmap window size.
  static int get mmapWindowSize {
    libgit2.git_libgit2_init();

    final out = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_mwindow_size(out);
    final result = out.value;
    calloc.free(out);

    return result;
  }

  static set mmapWindowSize(int value) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_mwindow_size(value);
  }

  /// Maximum memory that will be mapped in total by the library.
  ///
  /// The default (0) is unlimited.
  static int get mmapWindowMappedLimit {
    libgit2.git_libgit2_init();

    final out = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_mwindow_mapped_limit(out);
    final result = out.value;
    calloc.free(out);

    return result;
  }

  static set mmapWindowMappedLimit(int value) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_mwindow_mapped_limit(value);
  }

  /// Maximum number of files that will be mapped at any time by the library.
  ///
  /// The default (0) is unlimited.
  static int get mmapWindowFileLimit {
    libgit2.git_libgit2_init();

    final out = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_mwindow_file_limit(out);
    final result = out.value;
    calloc.free(out);

    return result;
  }

  static set mmapWindowFileLimit(int value) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_mwindow_file_limit(value);
  }

  /// Returns search path for a given [level] of config data.
  ///
  /// [level] must be one of:
  /// - [GitConfigLevel.system]
  /// - [GitConfigLevel.global]
  /// - [GitConfigLevel.xdg]
  /// - [GitConfigLevel.programData]
  static String getConfigSearchPath(GitConfigLevel level) {
    libgit2.git_libgit2_init();

    final out = calloc<git_buf>();
    libgit2Opts.git_libgit2_opts_get_search_path(level.value, out);
    final result = out.ref.ptr.toDartString(length: out.ref.size);

    libgit2.git_buf_dispose(out);
    calloc.free(out);

    return result;
  }

  /// Sets the search path for a [level] of config data. The search path
  /// applied to shared attributes and ignore files.
  ///
  /// [path] lists directories delimited by `:`.
  /// Pass null to reset to the default (generally based on environment
  /// variables). Use magic path `$PATH` to include the old value of the path
  /// (if you want to prepend or append, for instance).
  ///
  /// [level] must be one of:
  /// - [GitConfigLevel.system]
  /// - [GitConfigLevel.global]
  /// - [GitConfigLevel.xdg]
  /// - [GitConfigLevel.programData]
  static void setConfigSearchPath({
    required GitConfigLevel level,
    required String? path,
  }) {
    libgit2.git_libgit2_init();

    final pathC = path?.toChar() ?? nullptr;
    libgit2Opts.git_libgit2_opts_set_search_path(level.value, pathC);
    calloc.free(pathC);
  }

  /// Sets the maximum data size for the given [type] of object to be
  /// considered eligible for caching in memory. Setting the [value] to
  /// zero means that that type of object will not be cached.
  ///
  /// Defaults to 0 for [GitObject.blob] (i.e. won't cache blobs) and 4k
  /// for [GitObject.commit], [GitObject.tree] and [GitObject.tag].
  static void setCacheObjectLimit({
    required GitObject type,
    required int value,
  }) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_cache_object_limit(type.value, value);
  }

  /// Sets the maximum total data size that will be cached in memory
  /// across all repositories before libgit2 starts evicting objects
  /// from the cache.  This is a soft limit, in that the library might
  /// briefly exceed it, but will start aggressively evicting objects
  /// from cache when that happens.
  ///
  /// The default cache size is 256MB.
  static void setCacheMaxSize(int bytes) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_cache_max_size(bytes);
  }

  /// [CachedMemory] object containing current bytes in cache and the maximum
  /// that would be allowed in the cache.
  static CachedMemory get cachedMemory {
    libgit2.git_libgit2_init();

    final current = calloc<Int>();
    final allowed = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_cached_memory(current, allowed);

    final result = CachedMemory._(
      current: current.value,
      allowed: allowed.value,
    );

    calloc.free(current);
    calloc.free(allowed);
    return result;
  }

  /// Enables caching.
  static void enableCaching() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_caching(1);
  }

  /// Disables caching completely.
  ///
  /// Because caches are repository-specific, disabling the cache
  /// cannot immediately clear all cached objects, but each cache will
  /// be cleared on the next attempt to update anything in it.
  static void disableCaching() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_caching(0);
  }

  /// Default template path.
  static String get templatePath {
    libgit2.git_libgit2_init();

    final out = calloc<git_buf>();
    libgit2Opts.git_libgit2_opts_get_template_path(out);
    final result = out.ref.ptr.toDartString(length: out.ref.size);

    libgit2.git_buf_dispose(out);
    calloc.free(out);

    return result;
  }

  static set templatePath(String path) {
    libgit2.git_libgit2_init();

    final pathC = path.toChar();
    libgit2Opts.git_libgit2_opts_set_template_path(pathC);

    calloc.free(pathC);
  }

  /// Sets the SSL certificate-authority locations.
  ///
  /// - [file] is the location of a file containing several
  ///   certificates concatenated together.
  /// - [path] is the location of a directory holding several
  ///   certificates, one per file.
  ///
  /// Either parameter may be null, but not both.
  ///
  /// Throws [ArgumentError] if both arguments are null.
  static void setSSLCertLocations({String? file, String? path}) {
    if (file == null && path == null) {
      throw ArgumentError("Both file and path can't be null");
    } else {
      libgit2.git_libgit2_init();

      final fileC = file?.toChar() ?? nullptr;
      final pathC = path?.toChar() ?? nullptr;

      libgit2Opts.git_libgit2_opts_set_ssl_cert_locations(fileC, pathC);

      calloc.free(fileC);
      calloc.free(pathC);
    }
  }

  /// Value of the User-Agent header.
  ///
  /// This value will be appended to "git/1.0", for compatibility with other
  /// git clients.
  static String get userAgent {
    libgit2.git_libgit2_init();

    final out = calloc<git_buf>();
    libgit2Opts.git_libgit2_opts_get_user_agent(out);
    final result = out.ref.ptr.toDartString(length: out.ref.size);

    libgit2.git_buf_dispose(out);
    calloc.free(out);

    return result;
  }

  static set userAgent(String userAgent) {
    libgit2.git_libgit2_init();

    final userAgentC = userAgent.toChar();
    libgit2Opts.git_libgit2_opts_set_user_agent(userAgentC);

    calloc.free(userAgentC);
  }

  /// Enables strict input validation when creating new objects
  /// to ensure that all inputs to the new objects are valid.
  ///
  /// For example, when this is enabled, the parent(s) and tree inputs
  /// will be validated when creating a new commit.
  ///
  /// Enabled by default.
  static void enableStrictObjectCreation() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_object_creation(1);
  }

  /// Disables strict input validation when creating new objects.
  ///
  /// Enabled by default.
  static void disableStrictObjectCreation() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_object_creation(0);
  }

  /// Enables validation of a symbolic ref target when creating it.
  ///
  /// For example, `foobar` is not a valid ref, therefore `foobar` is
  /// not a valid target for a symbolic ref by default, whereas
  /// `refs/heads/foobar` is.
  ///
  /// Disabling this bypasses validation so that an arbitrary strings
  /// such as `foobar` can be used for a symbolic ref target.
  ///
  /// Enabled by default.
  static void enableStrictSymbolicRefCreation() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_symbolic_ref_creation(1);
  }

  /// Disables validation of a symbolic ref target when creating it.
  ///
  /// For example, `foobar` is not a valid ref, therefore `foobar` is
  /// not a valid target for a symbolic ref by default, whereas
  /// `refs/heads/foobar` is.
  ///
  /// Disabling this bypasses validation so that an arbitrary strings
  /// such as `foobar` can be used for a symbolic ref target.
  ///
  /// Enabled by default.
  static void disableStrictSymbolicRefCreation() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_symbolic_ref_creation(0);
  }

  /// Enables the use of "offset deltas" when creating packfiles,
  /// and the negotiation of them when talking to a remote server.
  ///
  /// Offset deltas store a delta base location as an offset into the
  /// packfile from the current location, which provides a shorter encoding
  /// and thus smaller resultant packfiles.
  ///
  /// Enabled by default.
  static void enableOffsetDelta() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_offset_delta(1);
  }

  /// Disables the use of "offset deltas" when creating packfiles,
  /// and the negotiation of them when talking to a remote server.
  ///
  /// Offset deltas store a delta base location as an offset into the
  /// packfile from the current location, which provides a shorter encoding
  /// and thus smaller resultant packfiles.
  ///
  /// Packfiles containing offset deltas can still be read.
  ///
  /// Enabled by default.
  static void disableOffsetDelta() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_offset_delta(0);
  }

  /// Enables synchronized writes of files in the gitdir using `fsync`
  /// (or the platform equivalent) to ensure that new object data
  /// is written to permanent storage, not simply cached.
  ///
  /// Disabled by default.
  static void enableFsyncGitdir() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_fsync_gitdir(1);
  }

  /// Disables synchronized writes of files in the gitdir using `fsync`
  /// (or the platform equivalent).
  ///
  /// Disabled by default.
  static void disableFsyncGitdir() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_fsync_gitdir(0);
  }

  /// Enables strict verification of object hashsums when reading objects from
  /// disk.
  ///
  /// This may impact performance due to an additional checksum calculation
  /// on each object.
  ///
  /// Enabled by default.
  static void enableStrictHashVerification() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_hash_verification(1);
  }

  /// Disables strict verification of object hashsums when reading objects from
  /// disk.
  ///
  /// Enabled by default.
  static void disableStrictHashVerification() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_strict_hash_verification(0);
  }

  /// Enables check for unsaved changes in the index before beginning any
  /// operation that reloads the index from disk (e.g., checkout).
  ///
  /// If there are unsaved changes, the instruction will fail (using
  /// the FORCE flag to checkout will still overwrite these changes).
  ///
  /// Enabled by default.
  static void enableUnsavedIndexSafety() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_unsaved_index_safety(1);
  }

  /// Disables check for unsaved changes in the index before beginning any
  /// operation that reloads the index from disk (e.g., checkout).
  ///
  /// If there are unsaved changes, the instruction will fail (using
  /// the FORCE flag to checkout will still overwrite these changes).
  ///
  /// Enabled by default.
  static void disableUnsavedIndexSafety() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_unsaved_index_safety(0);
  }

  /// Maximum number of objects libgit2 will allow in a pack file when
  /// downloading a pack file from a remote. This can be used to limit maximum
  /// memory usage when fetching from an untrusted remote.
  static int get packMaxObjects {
    libgit2.git_libgit2_init();

    final out = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_pack_max_objects(out);
    final result = out.value;
    calloc.free(out);

    return result;
  }

  static set packMaxObjects(int value) {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_set_pack_max_objects(value);
  }

  /// Enables checks of .keep file existence to be skipped when accessing
  /// packfiles.
  static void enablePackKeepFileChecks() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_disable_pack_keep_file_checks(0);
  }

  /// Disables checks of .keep file existence to be skipped when accessing
  /// packfiles, which can help performance with remote filesystems.
  static void disablePackKeepFileChecks() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_disable_pack_keep_file_checks(1);
  }

  /// When connecting to a server using NTLM or Negotiate
  /// authentication, use expect/continue when POSTing data.
  ///
  /// This option is not available on Windows.
  static void enableHttpExpectContinue() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_http_expect_continue(1);
  }

  /// When connecting to a server using NTLM or Negotiate
  /// authentication, don't use expect/continue when POSTing data.
  ///
  /// This option is not available on Windows.
  static void disableHttpExpectContinue() {
    libgit2.git_libgit2_init();
    libgit2Opts.git_libgit2_opts_enable_http_expect_continue(0);
  }

  /// List of git extensions that are supported.
  ///
  /// This is the list of built-in extensions supported by libgit2 and
  /// custom extensions that have been added.
  ///
  /// Extensions supported by libgit2 may be negated by prefixing
  /// them with a `!`. For example: setting extensions to
  /// `"!noop", "newext"` indicates that the caller does not want
  /// to support repositories with the `noop` extension but does want
  /// to support repositories with the `newext` extension.
  ///
  /// Extensions that have been negated will not be returned.
  static List<String> get extensions {
    libgit2.git_libgit2_init();

    final array = calloc<git_strarray>();
    libgit2Opts.git_libgit2_opts_get_extensions(array);

    final result = <String>[
      for (var i = 0; i < array.ref.count; i++)
        array.ref.strings.elementAt(i).value.toDartString()
    ];

    calloc.free(array);

    return result;
  }

  static set extensions(List<String> extensions) {
    libgit2.git_libgit2_init();

    final array = calloc<Pointer<Char>>(extensions.length);
    for (var i = 0; i < extensions.length; i++) {
      array[i] = extensions[i].toChar();
    }

    libgit2Opts.git_libgit2_opts_set_extensions(array, extensions.length);

    for (var i = 0; i < extensions.length; i++) {
      calloc.free(array[i]);
    }
    calloc.free(array);
  }

  /// Owner validation setting for repository directories.
  ///
  /// Enabled by default.
  static bool get ownerValidation {
    libgit2.git_libgit2_init();

    final out = calloc<Int>();
    libgit2Opts.git_libgit2_opts_get_owner_validation(out);
    final result = out.value;
    calloc.free(out);

    return result == 1 || false;
  }

  static set ownerValidation(bool value) {
    libgit2.git_libgit2_init();

    final valueC = value ? 1 : 0;
    libgit2Opts.git_libgit2_opts_set_owner_validation(valueC);
  }
}

/// Current bytes in cache and the maximum that would be allowed in the cache.
class CachedMemory {
  const CachedMemory._({required this.current, required this.allowed});

  final int current;
  final int allowed;

  @override
  String toString() {
    return 'CachedMemory{current: $current, allowed: $allowed}';
  }
}
