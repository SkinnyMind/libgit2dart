import 'dart:io';

import 'package:test/test.dart';
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
    setUp(() {
      File('$tmpDir/$configFileName').writeAsStringSync(contents);
      config = Config.open('$tmpDir/$configFileName');
    });

    tearDown(() {
      config.free();
      File('$tmpDir/$configFileName').deleteSync();
    });

    test('opens file successfully with provided path', () {
      expect(config, isA<Config>());
    });

    test('returns map with variables and values', () {
      expect(config.variables['remote.origin.url'], equals('someurl'));
    });

    group('get value', () {
      test('returns value of variable', () {
        expect(config['core.bare'], equals('false'));
      });

      test('throws when variable isn\'t found', () {
        expect(
          () => config['not.there'],
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('set value', () {
      test('sets boolean value for provided variable', () {
        config['core.bare'] = true;
        expect(config['core.bare'], equals('true'));
      });

      test('sets integer value for provided variable', () {
        config['core.repositoryformatversion'] = 1;
        expect(config['core.repositoryformatversion'], equals('1'));
      });

      test('sets string value for provided variable', () {
        config['remote.origin.url'] = 'updated';
        expect(config['remote.origin.url'], equals('updated'));
      });
    });

    group('delete', () {
      test('successfully deletes entry', () {
        expect(config['core.bare'], equals('false'));
        config.delete('core.bare');
        expect(config.variables['core.bare'], isNull);
      });

      test('throws on deleting non existing variable', () {
        expect(
          () => config.delete('not.there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('get multivar values', () {
      test('returns list of values', () {
        expect(
          config.multivar('core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );
      });

      test('returns list of values for provided regexp', () {
        expect(
          config.multivar('core.gitproxy', regexp: 'for kernel.org\$'),
          ['proxy-command for kernel.org'],
        );
      });

      test('returns empty list if multivar not found', () {
        expect(config.multivar('not.there'), equals([]));
      });
    });

    group('setMultivarValue()', () {
      test('sets value of multivar', () {
        config.setMultivar('core.gitproxy', 'default', 'updated');
        final multivarValues = config.multivar('core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, contains('updated'));
      });

      test('sets value for all multivar values when regexp is empty', () {
        config.setMultivar('core.gitproxy', '', 'updated');
        final multivarValues = config.multivar('core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, isNot(contains('proxy-command for kernel.org')));
        expect(multivarValues, contains('updated'));
        expect(multivarValues.length, equals(2));
      });
    });

    group('deleteMultivar()', () {
      test('successfully deletes value of a multivar', () {
        expect(
          config.multivar('core.gitproxy', regexp: 'for kernel.org\$'),
          ['proxy-command for kernel.org'],
        );

        config.deleteMultivar('core.gitproxy', 'for kernel.org\$');

        expect(
          config.multivar('core.gitproxy', regexp: 'for kernel.org\$'),
          [],
        );
      });

      test('successfully deletes all values of a multivar when regexp is empty',
          () {
        expect(
          config.multivar('core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );

        config.deleteMultivar('core.gitproxy', '');

        expect(config.multivar('core.gitproxy'), []);
      });
    });
  });
}
