// coverage:ignore-file

import 'dart:ffi' as ffi;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';

/// Bindings to libgit2 global options
class Libgit2Opts {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  Libgit2Opts(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// Get the maximum mmap window size.
  int git_libgit2_opts_get_mwindow_size(ffi.Pointer<ffi.Int> out) {
    return _git_libgit2_opts_get_int(
      git_libgit2_opt_t.GIT_OPT_GET_MWINDOW_SIZE,
      out,
    );
  }

  /// Set the maximum mmap window size.
  int git_libgit2_opts_set_mwindow_size(int value) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_MWINDOW_SIZE,
      value,
    );
  }

  /// Get the maximum memory that will be mapped in total by the library.
  ///
  /// The default (0) is unlimited.
  int git_libgit2_opts_get_mwindow_mapped_limit(ffi.Pointer<ffi.Int> out) {
    return _git_libgit2_opts_get_int(
      git_libgit2_opt_t.GIT_OPT_GET_MWINDOW_MAPPED_LIMIT,
      out,
    );
  }

  /// Set the maximum amount of memory that can be mapped at any time by the
  /// library.
  int git_libgit2_opts_set_mwindow_mapped_limit(int value) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_MWINDOW_MAPPED_LIMIT,
      value,
    );
  }

  /// Get the maximum number of files that will be mapped at any time by the
  /// library.
  ///
  /// The default (0) is unlimited.
  int git_libgit2_opts_get_mwindow_file_limit(ffi.Pointer<ffi.Int> out) {
    return _git_libgit2_opts_get_int(
      git_libgit2_opt_t.GIT_OPT_GET_MWINDOW_FILE_LIMIT,
      out,
    );
  }

  /// Set the maximum number of files that can be mapped at any time by the
  /// library.
  int git_libgit2_opts_set_mwindow_file_limit(int value) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_MWINDOW_FILE_LIMIT,
      value,
    );
  }

  /// Get the search path for a given level of config data.
  ///
  /// [level] must be one of `GIT_CONFIG_LEVEL_SYSTEM`,
  /// `GIT_CONFIG_LEVEL_GLOBAL`, `GIT_CONFIG_LEVEL_XDG`, or
  /// `GIT_CONFIG_LEVEL_PROGRAMDATA`.
  ///
  /// The search path is written to the [out] buffer.
  int git_libgit2_opts_get_search_path(int level, ffi.Pointer<git_buf> out) {
    return _git_libgit2_opts_get_search_path(
      git_libgit2_opt_t.GIT_OPT_GET_SEARCH_PATH,
      level,
      out,
    );
  }

  /// Set the search path for a level of config data. The search path applied
  /// to shared attributes and ignore files, too.
  ///
  /// [path] lists directories delimited by GIT_PATH_LIST_SEPARATOR.
  /// Pass NULL to reset to the default (generally based on environment
  /// variables). Use magic path `$PATH` to include the old value of the path
  /// (if you want to prepend or append, for instance).
  ///
  /// [level] must be one of `GIT_CONFIG_LEVEL_SYSTEM`,
  /// `GIT_CONFIG_LEVEL_GLOBAL`, `GIT_CONFIG_LEVEL_XDG`, or
  /// `GIT_CONFIG_LEVEL_PROGRAMDATA`.
  int git_libgit2_opts_set_search_path(int level, ffi.Pointer<ffi.Char> path) {
    return _git_libgit2_opts_set_search_path(
      git_libgit2_opt_t.GIT_OPT_SET_SEARCH_PATH,
      level,
      path,
    );
  }

  /// Set the maximum data size for the given [type] of object to be
  /// considered eligible for caching in memory. Setting the [value] to
  /// zero means that that type of object will not be cached.
  ///
  /// Defaults to 0 for GIT_OBJECT_BLOB (i.e. won't cache blobs) and 4k
  /// for GIT_OBJECT_COMMIT, GIT_OBJECT_TREE, and GIT_OBJECT_TAG.
  int git_libgit2_opts_set_cache_object_limit(int type, int value) {
    return _git_libgit2_opts_set_cache_object_limit(
      git_libgit2_opt_t.GIT_OPT_SET_CACHE_OBJECT_LIMIT,
      type,
      value,
    );
  }

  /// Set the maximum total data size that will be cached in memory
  /// across all repositories before libgit2 starts evicting objects
  /// from the cache.  This is a soft limit, in that the library might
  /// briefly exceed it, but will start aggressively evicting objects
  /// from cache when that happens.
  ///
  /// The default cache size is 256MB.
  int git_libgit2_opts_set_cache_max_size(int bytes) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_CACHE_MAX_SIZE,
      bytes,
    );
  }

  /// Get the current bytes in cache and the maximum that would be
  /// allowed in the cache.
  int git_libgit2_opts_get_cached_memory(
    ffi.Pointer<ffi.Int> current,
    ffi.Pointer<ffi.Int> allowed,
  ) {
    return _git_libgit2_opts_get_cached_memory(
      git_libgit2_opt_t.GIT_OPT_GET_CACHED_MEMORY,
      current,
      allowed,
    );
  }

  /// Enable or disable caching completely.
  ///
  /// Because caches are repository-specific, disabling the cache
  /// cannot immediately clear all cached objects, but each cache will
  /// be cleared on the next attempt to update anything in it.
  int git_libgit2_opts_enable_caching(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_CACHING,
      enabled,
    );
  }

  /// Get the default template path.
  /// The path is written to the `out` buffer.
  int git_libgit2_opts_get_template_path(ffi.Pointer<git_buf> out) {
    return _git_libgit2_opts_get_buf(
      git_libgit2_opt_t.GIT_OPT_GET_TEMPLATE_PATH,
      out,
    );
  }

  /// Set the default template [path].
  int git_libgit2_opts_set_template_path(ffi.Pointer<ffi.Char> path) {
    return _git_libgit2_opts_set_char(
      git_libgit2_opt_t.GIT_OPT_SET_TEMPLATE_PATH,
      path,
    );
  }

  /// Set the SSL certificate-authority locations.
  ///
  /// - [file] is the location of a file containing several
  ///   certificates concatenated together.
  /// - [path] is the location of a directory holding several
  ///   certificates, one per file.
  ///
  /// Either parameter may be `NULL`, but not both.
  int git_libgit2_opts_set_ssl_cert_locations(
    ffi.Pointer<ffi.Char> file,
    ffi.Pointer<ffi.Char> path,
  ) {
    return _git_libgit2_opts_set_ssl_cert_locations(
      git_libgit2_opt_t.GIT_OPT_SET_SSL_CERT_LOCATIONS,
      file,
      path,
    );
  }

  /// Get the value of the User-Agent header.
  ///
  /// The User-Agent is written to the `out` buffer.
  int git_libgit2_opts_get_user_agent(ffi.Pointer<git_buf> out) {
    return _git_libgit2_opts_get_buf(
      git_libgit2_opt_t.GIT_OPT_GET_USER_AGENT,
      out,
    );
  }

  /// Set the value of the User-Agent header. This value will be
  /// appended to "git/1.0", for compatibility with other git clients.
  ///
  /// - [user_agent] is the value that will be delivered as the
  ///   User-Agent header on HTTP requests.
  int git_libgit2_opts_set_user_agent(ffi.Pointer<ffi.Char> user_agent) {
    return _git_libgit2_opts_set_char(
      git_libgit2_opt_t.GIT_OPT_SET_USER_AGENT,
      user_agent,
    );
  }

  /// Enable strict input validation when creating new objects
  /// to ensure that all inputs to the new objects are valid.
  ///
  /// For example, when this is enabled, the parent(s) and tree inputs
  /// will be validated when creating a new commit.
  ///
  /// This defaults to enabled.
  int git_libgit2_opts_enable_strict_object_creation(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_STRICT_OBJECT_CREATION,
      enabled,
    );
  }

  /// Validate the target of a symbolic ref when creating it.
  ///
  /// For example, `foobar` is not a valid ref, therefore `foobar` is
  /// not a valid target for a symbolic ref by default, whereas
  /// `refs/heads/foobar` is.
  ///
  /// Disabling this bypasses validation so that an arbitrary strings
  /// such as `foobar` can be used for a symbolic ref target.
  ///
  /// This defaults to enabled.
  int git_libgit2_opts_enable_strict_symbolic_ref_creation(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_STRICT_SYMBOLIC_REF_CREATION,
      enabled,
    );
  }

  /// Enable or disable the use of "offset deltas" when creating packfiles,
  /// and the negotiation of them when talking to a remote server.
  ///
  /// Offset deltas store a delta base location as an offset into the
  /// packfile from the current location, which provides a shorter encoding
  /// and thus smaller resultant packfiles.
  ///
  /// Packfiles containing offset deltas can still be read.
  ///
  /// This defaults to enabled.
  int git_libgit2_opts_enable_offset_delta(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_OFS_DELTA,
      enabled,
    );
  }

  /// Enable synchronized writes of files in the gitdir using `fsync`
  /// (or the platform equivalent) to ensure that new object data
  /// is written to permanent storage, not simply cached.
  ///
  /// This defaults to disabled.
  int git_libgit2_opts_enable_fsync_gitdir(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_FSYNC_GITDIR,
      enabled,
    );
  }

  /// Enable strict verification of object hashsums when reading
  /// objects from disk.
  ///
  /// This may impact performance due to an additional checksum calculation
  /// on each object.
  ///
  /// This defaults to enabled.
  int git_libgit2_opts_enable_strict_hash_verification(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_STRICT_HASH_VERIFICATION,
      enabled,
    );
  }

  /// Ensure that there are no unsaved changes in the index before
  /// beginning any operation that reloads the index from disk (e.g.,
  /// checkout).
  ///
  /// If there are unsaved changes, the instruction will fail (using
  /// the FORCE flag to checkout will still overwrite these changes).
  int git_libgit2_opts_enable_unsaved_index_safety(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_UNSAVED_INDEX_SAFETY,
      enabled,
    );
  }

  /// Get the maximum number of objects libgit2 will allow in a pack
  /// file when downloading a pack file from a remote. This can be
  /// used to limit maximum memory usage when fetching from an untrusted
  /// remote.
  int git_libgit2_opts_get_pack_max_objects(ffi.Pointer<ffi.Int> out) {
    return _git_libgit2_opts_get_int(
      git_libgit2_opt_t.GIT_OPT_GET_PACK_MAX_OBJECTS,
      out,
    );
  }

  /// Set the maximum number of objects libgit2 will allow in a pack
  /// file when downloading a pack file from a remote.
  int git_libgit2_opts_set_pack_max_objects(int value) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_PACK_MAX_OBJECTS,
      value,
    );
  }

  /// This will cause .keep file existence checks to be skipped when
  /// accessing packfiles, which can help performance with remote filesystems.
  int git_libgit2_opts_disable_pack_keep_file_checks(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_DISABLE_PACK_KEEP_FILE_CHECKS,
      enabled,
    );
  }

  /// When connecting to a server using NTLM or Negotiate
  /// authentication, use expect/continue when POSTing data.
  ///
  /// This option is not available on Windows.
  int git_libgit2_opts_enable_http_expect_continue(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_ENABLE_HTTP_EXPECT_CONTINUE,
      enabled,
    );
  }

  /// Gets the owner validation setting for repository directories.
  int git_libgit2_opts_get_owner_validation(ffi.Pointer<ffi.Int> out) {
    return _git_libgit2_opts_get_int(
      git_libgit2_opt_t.GIT_OPT_GET_OWNER_VALIDATION,
      out,
    );
  }

  /// Set that repository directories should be owned by the current
  /// user. The default is to validate ownership.
  int git_libgit2_opts_set_owner_validation(int enabled) {
    return _git_libgit2_opts_set_int(
      git_libgit2_opt_t.GIT_OPT_SET_OWNER_VALIDATION,
      enabled,
    );
  }

  /// Returns the list of git extensions that are supported.
  /// This is the list of built-in extensions supported by libgit2 and
  /// custom extensions that have been added with [git_libgit2_opts_set_extensions].
  ///
  /// Extensions that have been negated will not be returned.
  int git_libgit2_opts_get_extensions(ffi.Pointer<git_strarray> out) {
    return _git_libgit2_opts_get_extensions(
      git_libgit2_opt_t.GIT_OPT_GET_EXTENSIONS,
      out,
    );
  }

  /// Set that the given git extensions are supported by the caller.
  ///
  /// Extensions supported by libgit2 may be negated by prefixing
  /// them with a `!`. For example: setting extensions to
  /// { "!noop", "newext" } indicates that the caller does not want
  /// to support repositories with the `noop` extension but does want
  /// to support repositories with the `newext` extension.
  int git_libgit2_opts_set_extensions(
    ffi.Pointer<ffi.Pointer<ffi.Char>> extensions,
    int len,
  ) {
    return _git_libgit2_opts_set_extensions(
      git_libgit2_opt_t.GIT_OPT_SET_EXTENSIONS,
      extensions,
      len,
    );
  }

  late final _git_libgit2_opts_get_intPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Int>)>>(
      'git_libgit2_opts');
  late final _git_libgit2_opts_get_int = _git_libgit2_opts_get_intPtr
      .asFunction<int Function(int, ffi.Pointer<ffi.Int>)>();

  late final _git_libgit2_opts_set_intPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Int)>>(
          'git_libgit2_opts');
  late final _git_libgit2_opts_set_int =
      _git_libgit2_opts_set_intPtr.asFunction<int Function(int, int)>();

  late final _git_libgit2_opts_get_bufPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Pointer<git_buf>)>>(
      'git_libgit2_opts');
  late final _git_libgit2_opts_get_buf = _git_libgit2_opts_get_bufPtr
      .asFunction<int Function(int, ffi.Pointer<git_buf>)>();

  late final _git_libgit2_opts_set_charPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Char>)>>(
      'git_libgit2_opts');
  late final _git_libgit2_opts_set_char = _git_libgit2_opts_set_charPtr
      .asFunction<int Function(int, ffi.Pointer<ffi.Char>)>();

  late final _git_libgit2_opts_get_search_pathPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Int, ffi.Int, ffi.Pointer<git_buf>)>>('git_libgit2_opts');
  late final _git_libgit2_opts_get_search_path =
      _git_libgit2_opts_get_search_pathPtr
          .asFunction<int Function(int, int, ffi.Pointer<git_buf>)>();

  late final _git_libgit2_opts_set_search_pathPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Int, ffi.Int, ffi.Pointer<ffi.Char>)>>('git_libgit2_opts');
  late final _git_libgit2_opts_set_search_path =
      _git_libgit2_opts_set_search_pathPtr
          .asFunction<int Function(int, int, ffi.Pointer<ffi.Char>)>();

  late final _git_libgit2_opts_set_cache_object_limitPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Int, ffi.Int)>>(
          'git_libgit2_opts');
  late final _git_libgit2_opts_set_cache_object_limit =
      _git_libgit2_opts_set_cache_object_limitPtr
          .asFunction<int Function(int, int, int)>();

  late final _git_libgit2_opts_get_cached_memoryPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Int>)>>('git_libgit2_opts');
  late final _git_libgit2_opts_get_cached_memory =
      _git_libgit2_opts_get_cached_memoryPtr.asFunction<
          int Function(int, ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Int>)>();

  late final _git_libgit2_opts_set_ssl_cert_locationsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>>('git_libgit2_opts');
  late final _git_libgit2_opts_set_ssl_cert_locations =
      _git_libgit2_opts_set_ssl_cert_locationsPtr.asFunction<
          int Function(int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  late final _git_libgit2_opts_get_extensionsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Int, ffi.Pointer<git_strarray>)>>('git_libgit2_opts');
  late final _git_libgit2_opts_get_extensions =
      _git_libgit2_opts_get_extensionsPtr
          .asFunction<int Function(int, ffi.Pointer<git_strarray>)>();

  late final _git_libgit2_opts_set_extensionsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Pointer<ffi.Char>>,
              ffi.Int)>>('git_libgit2_opts');
  late final _git_libgit2_opts_set_extensions =
      _git_libgit2_opts_set_extensionsPtr.asFunction<
          int Function(int, ffi.Pointer<ffi.Pointer<ffi.Char>>, int)>();
}
