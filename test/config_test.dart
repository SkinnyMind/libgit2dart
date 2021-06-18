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
\trepositoryformatversion = 0
\tbare = false
\tgitproxy = proxy-command for kernel.org
\tgitproxy = default-proxy
[remote "origin"]
\turl = someurl
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

    group('getValue()', () {
      test('returns value of variable', () {
        expect(config.getValue('core.bare'), equals('false'));
      });

      test('throws when variable isn\'t found', () {
        expect(
          () => config.getValue('not.there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('setValue()', () {
      test('sets boolean value for provided variable', () {
        config.setValue('core.bare', true);
        expect(config.variables['core.bare'], equals('true'));
      });

      test('sets integer value for provided variable', () {
        config.setValue('core.repositoryformatversion', 1);
        expect(config.variables['core.repositoryformatversion'], equals('1'));
      });

      test('sets string value for provided variable', () {
        config.setValue('remote.origin.url', 'updated');
        expect(config.variables['remote.origin.url'], equals('updated'));
      });
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

    test('sets value of multivar', () {
      config.setMultivar('core.gitproxy', 'default', 'updated');
      final multivarValues = config.getMultivar('core.gitproxy');
      expect(multivarValues, isNot(contains('default-proxy')));
      expect(multivarValues, contains('updated'));
    });

    test('sets value for all multivar values when regexp is empty', () {
      config.setMultivar('core.gitproxy', '', 'updated');
      final multivarValues = config.getMultivar('core.gitproxy');
      expect(multivarValues, isNot(contains('default-proxy')));
      expect(multivarValues, isNot(contains('proxy-command for kernel.org')));
      expect(multivarValues, contains('updated'));
      expect(multivarValues.length, equals(2));
    });
  });
  ;
}
