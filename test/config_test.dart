import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:libgit2dart/src/config.dart';
import 'package:libgit2dart/src/error.dart';

void main() {
  final tmpDir = Directory.systemTemp.path;
  const configFileName = 'test_config';
  const contents = '''
[core]
  repositoryformatversion = 0
  bare = false
  gitproxy = proxy-command for kernel.org
  gitproxy = default-proxy
[remote "origin"]
  url = someurl
''';

  late Config config;

  group('Config', () {
    setUpAll(() {
      libgit2.git_libgit2_init();
    });

    setUp(() {
      File('$tmpDir/$configFileName').writeAsStringSync(contents);
      config = Config.open(path: '$tmpDir/$configFileName');
    });

    tearDown(() {
      config.close();
      File('$tmpDir/$configFileName').deleteSync();
    });

    tearDownAll(() {
      libgit2.git_libgit2_shutdown();
    });

    test('opens file successfully with provided path', () {
      expect(config, isA<Config>());
    });

    test('gets entries of file', () {
      expect(config.variables['core.repositoryformatversion'], equals('0'));
    });

    test('sets boolean value for provided key', () {
      config.setVariable('core.bare', true);
      expect(config.variables['core.bare'], equals('true'));
    });

    test('sets integer value for provided key', () {
      config.setVariable('core.repositoryformatversion', 1);
      expect(config.variables['core.repositoryformatversion'], equals('1'));
    });

    test('sets string value for provided key', () {
      config.setVariable('remote.origin.url', 'updated');
      expect(config.variables['remote.origin.url'], equals('updated'));
    });

    test('deletes variable', () {
      config.deleteVariable('core.bare');
      expect(config.variables['core.bare'], isNull);
    });

    test('throws on deleting non existing variable', () {
      expect(
        () => config.deleteVariable('not.there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns values of multivar', () {
      expect(
        config.getMultivar('core.gitproxy'),
        [
          'proxy-command for kernel.org',
          'default-proxy',
        ],
      );
    });

    test('returns values of multivar with regexp', () {
      expect(
        config.getMultivar('core.gitproxy', regexp: 'for kernel.org\$'),
        ['proxy-command for kernel.org'],
      );
    });
  });
  ;
}
