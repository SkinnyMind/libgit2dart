import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

void main() {
  group('Features', () {
    test('returns list of compile time options for libgit2', () {
      expect(
        Features.list,
        {GitFeature.threads, GitFeature.https, GitFeature.ssh, GitFeature.nsec},
      );
    });
  });
}
