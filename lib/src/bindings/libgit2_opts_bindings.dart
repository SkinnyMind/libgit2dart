// coverage:ignore-file

import 'dart:ffi' as ffi;

/// Bindings to libgit2 global options
class Libgit2Opts {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  Libgit2Opts(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// Set or query a library global option
  ///
  /// Available options:
  ///
  /// * opts(GIT_OPT_GET_MWINDOW_SIZE, size_t *):
  ///
  /// > Get the maximum mmap window size
  ///
  /// * opts(GIT_OPT_SET_MWINDOW_SIZE, size_t):
  ///
  /// > Set the maximum mmap window size
  ///
  /// * opts(GIT_OPT_GET_MWINDOW_MAPPED_LIMIT, size_t *):
  ///
  /// > Get the maximum memory that will be mapped in total by the library
  ///
  /// * opts(GIT_OPT_SET_MWINDOW_MAPPED_LIMIT, size_t):
  ///
  /// > Set the maximum amount of memory that can be mapped at any time
  /// > by the library
  ///
  /// * opts(GIT_OPT_GET_MWINDOW_FILE_LIMIT, size_t *):
  ///
  /// > Get the maximum number of files that will be mapped at any time by the
  /// > library
  ///
  /// * opts(GIT_OPT_SET_MWINDOW_FILE_LIMIT, size_t):
  ///
  /// > Set the maximum number of files that can be mapped at any time
  /// > by the library. The default (0) is unlimited.
  ///
  /// * opts(GIT_OPT_GET_SEARCH_PATH, int level, git_buf *buf)
  ///
  /// > Get the search path for a given level of config data.  "level" must
  /// > be one of `GIT_CONFIG_LEVEL_SYSTEM`, `GIT_CONFIG_LEVEL_GLOBAL`,
  /// > `GIT_CONFIG_LEVEL_XDG`, or `GIT_CONFIG_LEVEL_PROGRAMDATA`.
  /// > The search path is written to the `out` buffer.
  ///
  /// * opts(GIT_OPT_SET_SEARCH_PATH, int level, const char *path)
  ///
  /// > Set the search path for a level of config data.  The search path
  /// > applied to shared attributes and ignore files, too.
  /// >
  /// > - `path` lists directories delimited by GIT_PATH_LIST_SEPARATOR.
  /// >   Pass NULL to reset to the default (generally based on environment
  /// >   variables).  Use magic path `$PATH` to include the old value
  /// >   of the path (if you want to prepend or append, for instance).
  /// >
  /// > - `level` must be `GIT_CONFIG_LEVEL_SYSTEM`,
  /// >   `GIT_CONFIG_LEVEL_GLOBAL`, `GIT_CONFIG_LEVEL_XDG`, or
  /// >   `GIT_CONFIG_LEVEL_PROGRAMDATA`.
  ///
  /// * opts(GIT_OPT_SET_CACHE_OBJECT_LIMIT, git_object_t type, size_t size)
  ///
  /// > Set the maximum data size for the given type of object to be
  /// > considered eligible for caching in memory.  Setting to value to
  /// > zero means that that type of object will not be cached.
  /// > Defaults to 0 for GIT_OBJECT_BLOB (i.e. won't cache blobs) and 4k
  /// > for GIT_OBJECT_COMMIT, GIT_OBJECT_TREE, and GIT_OBJECT_TAG.
  ///
  /// * opts(GIT_OPT_SET_CACHE_MAX_SIZE, ssize_t max_storage_bytes)
  ///
  /// > Set the maximum total data size that will be cached in memory
  /// > across all repositories before libgit2 starts evicting objects
  /// > from the cache.  This is a soft limit, in that the library might
  /// > briefly exceed it, but will start aggressively evicting objects
  /// > from cache when that happens.  The default cache size is 256MB.
  ///
  /// * opts(GIT_OPT_ENABLE_CACHING, int enabled)
  ///
  /// > Enable or disable caching completely.
  /// >
  /// > Because caches are repository-specific, disabling the cache
  /// > cannot immediately clear all cached objects, but each cache will
  /// > be cleared on the next attempt to update anything in it.
  ///
  /// * opts(GIT_OPT_GET_CACHED_MEMORY, ssize_t *current, ssize_t *allowed)
  ///
  /// > Get the current bytes in cache and the maximum that would be
  /// > allowed in the cache.
  ///
  /// * opts(GIT_OPT_GET_TEMPLATE_PATH, git_buf *out)
  ///
  /// > Get the default template path.
  /// > The path is written to the `out` buffer.
  ///
  /// * opts(GIT_OPT_SET_TEMPLATE_PATH, const char *path)
  ///
  /// > Set the default template path.
  /// >
  /// > - `path` directory of template.
  ///
  /// * opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, const char *file, const char *path)
  ///
  /// > Set the SSL certificate-authority locations.
  /// >
  /// > - `file` is the location of a file containing several
  /// >   certificates concatenated together.
  /// > - `path` is the location of a directory holding several
  /// >   certificates, one per file.
  /// >
  /// > Either parameter may be `NULL`, but not both.
  ///
  /// * opts(GIT_OPT_SET_USER_AGENT, const char *user_agent)
  ///
  /// > Set the value of the User-Agent header.  This value will be
  /// > appended to "git/1.0", for compatibility with other git clients.
  /// >
  /// > - `user_agent` is the value that will be delivered as the
  /// >   User-Agent header on HTTP requests.
  ///
  /// * opts(GIT_OPT_SET_WINDOWS_SHAREMODE, unsigned long value)
  ///
  /// > Set the share mode used when opening files on Windows.
  /// > For more information, see the documentation for CreateFile.
  /// > The default is: FILE_SHARE_READ | FILE_SHARE_WRITE.  This is
  /// > ignored and unused on non-Windows platforms.
  ///
  /// * opts(GIT_OPT_GET_WINDOWS_SHAREMODE, unsigned long *value)
  ///
  /// > Get the share mode used when opening files on Windows.
  ///
  /// * opts(GIT_OPT_ENABLE_STRICT_OBJECT_CREATION, int enabled)
  ///
  /// > Enable strict input validation when creating new objects
  /// > to ensure that all inputs to the new objects are valid.  For
  /// > example, when this is enabled, the parent(s) and tree inputs
  /// > will be validated when creating a new commit.  This defaults
  /// > to enabled.
  ///
  /// * opts(GIT_OPT_ENABLE_STRICT_SYMBOLIC_REF_CREATION, int enabled)
  ///
  /// > Validate the target of a symbolic ref when creating it.  For
  /// > example, `foobar` is not a valid ref, therefore `foobar` is
  /// > not a valid target for a symbolic ref by default, whereas
  /// > `refs/heads/foobar` is.  Disabling this bypasses validation
  /// > so that an arbitrary strings such as `foobar` can be used
  /// > for a symbolic ref target.  This defaults to enabled.
  ///
  /// * opts(GIT_OPT_SET_SSL_CIPHERS, const char *ciphers)
  ///
  /// > Set the SSL ciphers use for HTTPS connections.
  /// >
  /// > - `ciphers` is the list of ciphers that are eanbled.
  ///
  /// * opts(GIT_OPT_GET_USER_AGENT, git_buf *out)
  ///
  /// > Get the value of the User-Agent header.
  /// > The User-Agent is written to the `out` buffer.
  ///
  /// * opts(GIT_OPT_ENABLE_OFS_DELTA, int enabled)
  ///
  /// > Enable or disable the use of "offset deltas" when creating packfiles,
  /// > and the negotiation of them when talking to a remote server.
  /// > Offset deltas store a delta base location as an offset into the
  /// > packfile from the current location, which provides a shorter encoding
  /// > and thus smaller resultant packfiles.
  /// > Packfiles containing offset deltas can still be read.
  /// > This defaults to enabled.
  ///
  /// * opts(GIT_OPT_ENABLE_FSYNC_GITDIR, int enabled)
  ///
  /// > Enable synchronized writes of files in the gitdir using `fsync`
  /// > (or the platform equivalent) to ensure that new object data
  /// > is written to permanent storage, not simply cached.  This
  /// > defaults to disabled.
  ///
  /// opts(GIT_OPT_ENABLE_STRICT_HASH_VERIFICATION, int enabled)
  ///
  /// > Enable strict verification of object hashsums when reading
  /// > objects from disk. This may impact performance due to an
  /// > additional checksum calculation on each object. This defaults
  /// > to enabled.
  ///
  /// opts(GIT_OPT_SET_ALLOCATOR, git_allocator *allocator)
  ///
  /// > Set the memory allocator to a different memory allocator. This
  /// > allocator will then be used to make all memory allocations for
  /// > libgit2 operations.  If the given `allocator` is NULL, then the
  /// > system default will be restored.
  ///
  /// opts(GIT_OPT_ENABLE_UNSAVED_INDEX_SAFETY, int enabled)
  ///
  /// > Ensure that there are no unsaved changes in the index before
  /// > beginning any operation that reloads the index from disk (eg,
  /// > checkout).  If there are unsaved changes, the instruction will
  /// > fail.  (Using the FORCE flag to checkout will still overwrite
  /// > these changes.)
  ///
  /// opts(GIT_OPT_GET_PACK_MAX_OBJECTS, size_t *out)
  ///
  /// > Get the maximum number of objects libgit2 will allow in a pack
  /// > file when downloading a pack file from a remote. This can be
  /// > used to limit maximum memory usage when fetching from an untrusted
  /// > remote.
  ///
  /// opts(GIT_OPT_SET_PACK_MAX_OBJECTS, size_t objects)
  ///
  /// > Set the maximum number of objects libgit2 will allow in a pack
  /// > file when downloading a pack file from a remote.
  ///
  /// opts(GIT_OPT_DISABLE_PACK_KEEP_FILE_CHECKS, int enabled)
  /// > This will cause .keep file existence checks to be skipped when
  /// > accessing packfiles, which can help performance with remote filesystems.
  ///
  /// opts(GIT_OPT_ENABLE_HTTP_EXPECT_CONTINUE, int enabled)
  /// > When connecting to a server using NTLM or Negotiate
  /// > authentication, use expect/continue when POSTing data.
  /// > This option is not available on Windows.
  ///
  /// opts(GIT_OPT_SET_ODB_PACKED_PRIORITY, int priority)
  /// > Override the default priority of the packed ODB backend which
  /// > is added when default backends are assigned to a repository
  ///
  /// opts(GIT_OPT_SET_ODB_LOOSE_PRIORITY, int priority)
  /// > Override the default priority of the loose ODB backend which
  /// > is added when default backends are assigned to a repository
  ///
  /// opts(GIT_OPT_GET_EXTENSIONS, git_strarray *out)
  /// > Returns the list of git extensions that are supported.  This
  /// > is the list of built-in extensions supported by libgit2 and
  /// > custom extensions that have been added with
  /// > `GIT_OPT_SET_EXTENSIONS`.  Extensions that have been negated
  /// > will not be returned.  The returned list should be released
  /// > with `git_strarray_dispose`.
  ///
  /// opts(GIT_OPT_SET_EXTENSIONS, const char **extensions, size_t len)
  /// > Set that the given git extensions are supported by the caller.
  /// > Extensions supported by libgit2 may be negated by prefixing
  /// > them with a `!`.  For example: setting extensions to
  /// > { "!noop", "newext" } indicates that the caller does not want
  /// > to support repositories with the `noop` extension but does want
  /// > to support repositories with the `newext` extension.
  ///
  /// opts(GIT_OPT_GET_OWNER_VALIDATION, int *enabled)
  /// > Gets the owner validation setting for repository
  /// > directories.
  ///
  /// opts(GIT_OPT_SET_OWNER_VALIDATION, int enabled)
  /// > Set that repository directories should be owned by the current
  /// > user. The default is to validate ownership.
  ///
  /// @param option Option key
  /// @param ... value to set the option
  /// @return 0 on success, <0 on failure
  int git_libgit2_opts(
    int option,
    ffi.Pointer<ffi.Char> out,
  ) {
    return _git_libgit2_opts(
      option,
      out,
    );
  }

  late final _git_libgit2_optsPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Pointer<ffi.Char>)>>(
      'git_libgit2_opts');
  late final _git_libgit2_opts = _git_libgit2_optsPtr
      .asFunction<int Function(int, ffi.Pointer<ffi.Char>)>();

  /// Set a library global option.
  ///
  /// Look at [git_libgit2_opts]
  int git_libgit2_opts_set(
    int option,
    int value,
  ) {
    return _git_libgit2_opts_set(
      option,
      value,
    );
  }

  late final _git_libgit2_opts_setPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Int)>>(
          'git_libgit2_opts');
  late final _git_libgit2_opts_set =
      _git_libgit2_opts_setPtr.asFunction<int Function(int, int)>();
}
