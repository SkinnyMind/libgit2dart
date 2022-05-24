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

    test(
        'sets and returns the owner validation setting for repository '
        'directories', () {
      final oldValue = Libgit2.ownerValidation;
      Libgit2.ownerValidation = !oldValue;
      expect(Libgit2.ownerValidation, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.ownerValidation = oldValue;
    });

    test('sets and returns the maximum mmap window size', () {
      final oldValue = Libgit2.mmapWindowSize;
      Libgit2.mmapWindowSize = 420 * 1024;
      expect(Libgit2.mmapWindowSize, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.mmapWindowSize = oldValue;
    });

    test(
        'sets and returns the maximum memory that will be mapped in total by '
        'the library', () {
      final oldValue = Libgit2.mmapWindowMappedLimit;
      Libgit2.mmapWindowMappedLimit = 420 * 1024;
      expect(Libgit2.mmapWindowMappedLimit, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.mmapWindowMappedLimit = oldValue;
    });

    test(
        'sets and returns the maximum number of files that will be mapped '
        'at any time by the library', () {
      final oldValue = Libgit2.mmapWindowFileLimit;
      Libgit2.mmapWindowFileLimit = 69;
      expect(Libgit2.mmapWindowFileLimit, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.mmapWindowFileLimit = oldValue;
    });

    test('sets and returns the search path for a given level of config data',
        () {
      const paths = '/tmp/global:/tmp/another';
      Libgit2.setConfigSearchPath(level: GitConfigLevel.global, path: paths);
      expect(Libgit2.getConfigSearchPath(GitConfigLevel.global), paths);

      // Reset to avoid side effects in later tests
      Libgit2.setConfigSearchPath(level: GitConfigLevel.global, path: null);
    });

    test(
        'sets the maximum data size for the given type of object '
        'to be considered eligible for caching in memory', () {
      expect(
        () => Libgit2.setCacheObjectLimit(type: GitObject.blob, value: 420),
        returnsNormally,
      );

      // Reset to avoid side effects in later tests
      Libgit2.setCacheObjectLimit(type: GitObject.blob, value: 0);
    });

    test('sets the maximum cache size', () {
      expect(Libgit2.cachedMemory.allowed, 256 * (1024 * 1024));

      Libgit2.setCacheMaxSize(128 * (1024 * 1024));

      expect(Libgit2.cachedMemory.allowed, 128 * (1024 * 1024));

      // Reset to avoid side effects in later tests
      Libgit2.setCacheMaxSize(256 * (1024 * 1024));
    });

    test('returns CachedMemory object', () {
      expect(Libgit2.cachedMemory.allowed, 256 * (1024 * 1024));
      expect(Libgit2.cachedMemory.toString(), contains('CachedMemory{'));
    });

    test('disables and enables caching', () {
      expect(() => Libgit2.disableCaching(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableCaching();
    });

    test('sets and returns the default template path', () {
      final oldValue = Libgit2.templatePath;
      Libgit2.templatePath = '/tmp/template';
      expect(Libgit2.templatePath, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.templatePath = oldValue;
    });

    test('sets location for ssl certificates', () {
      expect(
        () => Libgit2.setSSLCertLocations(file: 'etc/ssl/cert.pem'),
        returnsNormally,
      );
      expect(
        () => Libgit2.setSSLCertLocations(path: 'etc/ssl/certs/'),
        returnsNormally,
      );
    });

    test('throws when trying to set both ssl certificates location to null',
        () {
      expect(
        () => Libgit2.setSSLCertLocations(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sets and returns the User-Agent header', () {
      final oldValue = Libgit2.userAgent;
      Libgit2.userAgent = 'Mozilla/5.0';
      expect(Libgit2.userAgent, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.userAgent = oldValue;
    });

    test('disables and enables strict object creation', () {
      expect(() => Libgit2.disableStrictObjectCreation(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableStrictObjectCreation();
    });

    test('disables and enables strict symbolic reference creation', () {
      expect(() => Libgit2.disableStrictSymbolicRefCreation(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableStrictSymbolicRefCreation();
    });

    test(
        'disables and enables the use of offset deltas when creating packfiles',
        () {
      expect(() => Libgit2.disableOffsetDelta(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableOffsetDelta();
    });

    test('enables and disables the fsync of files in gitdir', () {
      expect(() => Libgit2.enableFsyncGitdir(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.disableFsyncGitdir();
    });

    test('disables and enables strict hash verification', () {
      expect(() => Libgit2.disableStrictHashVerification(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableStrictHashVerification();
    });

    test('disables and enables check for unsaved changes in index', () {
      expect(() => Libgit2.disableUnsavedIndexSafety(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enableUnsavedIndexSafety();
    });

    test('sets and returns the pack maximum objects', () {
      final oldValue = Libgit2.packMaxObjects;
      Libgit2.packMaxObjects = 69;
      expect(Libgit2.packMaxObjects, isNot(oldValue));

      // Reset to avoid side effects in later tests
      Libgit2.packMaxObjects = oldValue;
    });

    test('disables and enables check for unsaved changes in index', () {
      expect(() => Libgit2.disablePackKeepFileChecks(), returnsNormally);

      // Reset to avoid side effects in later tests
      Libgit2.enablePackKeepFileChecks();
    });

    test(
      'disables and enables check for unsaved changes in index',
      testOn: '!windows',
      () {
        expect(() => Libgit2.disableHttpExpectContinue(), returnsNormally);

        // Reset to avoid side effects in later tests
        Libgit2.enableHttpExpectContinue();
      },
    );

    test('sets and returns the list of git extensions', () {
      Libgit2.extensions = ['newext', 'anotherext'];
      expect(Libgit2.extensions, ['noop', 'newext', 'anotherext']);

      // Reset to avoid side effects in later tests
      Libgit2.extensions = ['!newext', '!anotherext'];
    });
  });
}
