import 'package:libgit2dart/libgit2dart.dart';
import 'util.dart';

class Features {
  /// Returns list of compile time options for libgit2.
  static List<GitFeature> get list {
    var result = <GitFeature>[];
    final featuresInt = libgit2.git_libgit2_features();

    for (var feature in GitFeature.values) {
      if (featuresInt & feature.value == feature.value) {
        result.add(feature);
      }
    }

    return result;
  }
}
