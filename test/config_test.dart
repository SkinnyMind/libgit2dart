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

    test('getEntries() returns map with variables and values', () {
      final entries = config.getEntries();
      expect(entries['remote.origin.url'], equals('someurl'));
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
        expect(config.getValue('core.bare'), equals('true'));
      });

      test('sets integer value for provided variable', () {
        config.setValue('core.repositoryformatversion', 1);
        expect(config.getValue('core.repositoryformatversion'), equals('1'));
      });

      test('sets string value for provided variable', () {
        config.setValue('remote.origin.url', 'updated');
        expect(config.getValue('remote.origin.url'), equals('updated'));
      });
    });

    group('deleteEntry()', () {
      test('successfully deletes entry', () {
        expect(config.getValue('core.bare'), equals('false'));
        config.deleteEntry('core.bare');
        final entries = config.getEntries();
        expect(entries['core.bare'], isNull);
      });

      test('throws on deleting non existing variable', () {
        expect(
          () => config.deleteEntry('not.there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('getMultivarValue()', () {
      test('returns values of multivar', () {
        expect(
          config.getMultivarValue('core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );
      });

      test('returns values of multivar for provided regexp', () {
        expect(
          config.getMultivarValue('core.gitproxy', regexp: 'for kernel.org\$'),
          ['proxy-command for kernel.org'],
        );
      });

      test('returns empty list if multivar not found', () {
        expect(config.getMultivarValue('not.there'), equals([]));
      });
    });

    group('setMultivarValue()', () {
      test('sets value of multivar', () {
        config.setMultivarValue('core.gitproxy', 'default', 'updated');
        final multivarValues = config.getMultivarValue('core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, contains('updated'));
      });

      test('sets value for all multivar values when regexp is empty', () {
        config.setMultivarValue('core.gitproxy', '', 'updated');
        final multivarValues = config.getMultivarValue('core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, isNot(contains('proxy-command for kernel.org')));
        expect(multivarValues, contains('updated'));
        expect(multivarValues.length, equals(2));
      });
    });

    group('deleteMultivar()', () {
      test('successfully deletes value of a multivar', () {
        expect(
          config.getMultivarValue('core.gitproxy', regexp: 'for kernel.org\$'),
          ['proxy-command for kernel.org'],
        );

        config.deleteMultivar('core.gitproxy', 'for kernel.org\$');

        expect(
          config.getMultivarValue('core.gitproxy', regexp: 'for kernel.org\$'),
          [],
        );
      });

      test('successfully deletes all values of a multivar when regexp is empty',
          () {
        expect(
          config.getMultivarValue('core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );

        config.deleteMultivar('core.gitproxy', '');

        expect(config.getMultivarValue('core.gitproxy'), []);
      });
    });
  });
}
