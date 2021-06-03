import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:libgit2dart/src/config.dart';

void main() {
  const configFileName = 'test_config';
  group('Config', () {
    setUpAll(() {
      libgit2.git_libgit2_init();
    });

    setUp(() {
      File('${Directory.current.path}/test/$configFileName').writeAsStringSync(
          '[core]\n\trepositoryformatversion = 0\n\tbare = false\n[remote "origin"]\n\turl = someurl');
    });

    tearDown(() {
      File('${Directory.current.path}/test/$configFileName').deleteSync();
    });

    tearDownAll(() {
      libgit2.git_libgit2_shutdown();
    });

    test('opens file successfully', () {
      final config = Config();
      expect(config, isA<Config>());
      config.close();
    });

    test('opens file successfully with provided path', () {
      final config = Config(path: 'test/$configFileName');
      expect(config, isA<Config>());
      config.close();
    });

    test('gets entries of file', () {
      final config = Config(path: 'test/$configFileName');
      expect(config.entries['core.repositoryformatversion'], equals('0'));
      config.close();
    });

    test('sets boolean value for provided key', () {
      final config = Config(path: 'test/$configFileName');
      config.setEntry('core.bare', true);
      expect(config.entries['core.bare'], equals('true'));
      config.close();
    });

    test('sets integer value for provided key', () {
      final config = Config(path: 'test/$configFileName');
      config.setEntry('core.repositoryformatversion', 1);
      expect(config.entries['core.repositoryformatversion'], equals('1'));
      config.close();
    });

    test('sets string value for provided key', () {
      final config = Config(path: 'test/$configFileName');
      config.setEntry('remote.origin.url', 'updated');
      expect(config.entries['remote.origin.url'], equals('updated'));
      config.close();
    });
  });
}
