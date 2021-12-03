import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:test/test.dart';

void main() {
  group('Libgit2', () {
    test('returns up to date version of libgit2', () {
      expect(Libgit2.version, libgit2Version);
    });

    test('returns list of options libgit2 was compiled with', () {
      expect(
        Libgit2.features,
        {GitFeature.threads, GitFeature.https, GitFeature.ssh, GitFeature.nsec},
      );
    });
  });
}
