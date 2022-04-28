import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/util.dart';

class Libgit2 {
  Libgit2._(); // coverage:ignore-line

  /// Libgit2 version number.
  static String get version {
    libgit2.git_libgit2_init();

    final major = calloc<Int32>();
    final minor = calloc<Int32>();
    final rev = calloc<Int32>();
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

  /// Owner validation setting for repository directories.
  static bool get ownerValidation {
    libgit2.git_libgit2_init();

    final out = calloc<Int8>();
    libgit2.git_libgit2_opts(
      git_libgit2_opt_t.GIT_OPT_GET_OWNER_VALIDATION,
      out,
    );
    final result = out.value;
    calloc.free(out);

    return result == 1 || false;
  }

  /// Sets owner validation setting for repository directories.
  static set ownerValidation(bool value) {
    libgit2.git_libgit2_init();
    final valueC = value ? 1 : 0;
    libgit2.git_libgit2_opts_set(
      git_libgit2_opt_t.GIT_OPT_SET_OWNER_VALIDATION,
      valueC,
    );
  }
}
