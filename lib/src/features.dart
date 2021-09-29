import 'util.dart';
import 'git_types.dart';

class Features {
  /// Returns list of compile time options for libgit2.
  static List<GitFeature> get list {
    var result = <GitFeature>[];
    final featuresInt = libgit2.git_libgit2_features();

    for (var flag in GitFeature.values) {
      if (featuresInt & flag.value == flag.value) {
        result.add(flag);
      }
    }

    return result;
  }
}
