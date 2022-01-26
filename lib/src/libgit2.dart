import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/util.dart';

class Libgit2 {
  Libgit2._(); // coverage:ignore-line

  /// Returns libgit2 version number.
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

  /// Returns list of options libgit2 was compiled with.
  static Set<GitFeature> get features {
    libgit2.git_libgit2_init();
    final featuresInt = libgit2.git_libgit2_features();
    return GitFeature.values
        .where((e) => featuresInt & e.value == e.value)
        .toSet();
  }
}
