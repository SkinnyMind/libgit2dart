import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/util.dart';

class Features {
  /// Returns list of compile time options for libgit2.
  static Set<GitFeature> get list {
    libgit2.git_libgit2_init();
    final featuresInt = libgit2.git_libgit2_features();
    return GitFeature.values
        .where((e) => featuresInt & e.value == e.value)
        .toSet();
  }
}
