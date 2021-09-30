import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

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

  setUp(() {
    File('$tmpDir/$configFileName').writeAsStringSync(contents);
    config = Config.open('$tmpDir/$configFileName');
  });

  tearDown(() {
    config.free();
    File('$tmpDir/$configFileName').deleteSync();
  });

  group('Config', () {
    test('opens file successfully with provided path', () {
      expect(config, isA<Config>());
    });

    test('returns config entries and their values', () {
      expect(config.length, 5);
      expect(config.last.name, 'remote.origin.url');
      expect(config.last.value, 'someurl');
      expect(config.last.includeDepth, 0);
      expect(config.last.level, GitConfigLevel.local);
    });

    group('get value', () {
      test('returns value of variable', () {
        expect(config['core.bare'].value, 'false');
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
        expect(config['core.bare'].value, 'true');
      });

      test('sets integer value for provided variable', () {
        config['core.repositoryformatversion'] = 1;
        expect(config['core.repositoryformatversion'].value, '1');
      });

      test('sets string value for provided variable', () {
        config['remote.origin.url'] = 'updated';
        expect(config['remote.origin.url'].value, 'updated');
      });
    });

    group('delete', () {
      test('successfully deletes entry', () {
        expect(config['core.bare'].value, 'false');
        config.delete('core.bare');
        expect(() => config['core.bare'], throwsA(isA<LibGit2Error>()));
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
          config.multivar(variable: 'core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );
      });

      test('returns list of values for provided regexp', () {
        expect(
          config.multivar(
            variable: 'core.gitproxy',
            regexp: 'for kernel.org\$',
          ),
          ['proxy-command for kernel.org'],
        );
      });

      test('returns empty list if multivar not found', () {
        expect(config.multivar(variable: 'not.there'), []);
      });
    });

    group('setMultivarValue()', () {
      test('sets value of multivar', () {
        config.setMultivar(
          variable: 'core.gitproxy',
          regexp: 'default',
          value: 'updated',
        );
        final multivarValues = config.multivar(variable: 'core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, contains('updated'));
      });

      test('sets value for all multivar values when regexp is empty', () {
        config.setMultivar(
          variable: 'core.gitproxy',
          regexp: '',
          value: 'updated',
        );
        final multivarValues = config.multivar(variable: 'core.gitproxy');
        expect(multivarValues, isNot(contains('default-proxy')));
        expect(multivarValues, isNot(contains('proxy-command for kernel.org')));
        expect(multivarValues, contains('updated'));
        expect(multivarValues.length, 2);
      });
    });

    group('deleteMultivar()', () {
      test('successfully deletes value of a multivar', () {
        expect(
          config.multivar(
            variable: 'core.gitproxy',
            regexp: 'for kernel.org\$',
          ),
          ['proxy-command for kernel.org'],
        );

        config.deleteMultivar(
          variable: 'core.gitproxy',
          regexp: 'for kernel.org\$',
        );

        expect(
          config.multivar(
            variable: 'core.gitproxy',
            regexp: 'for kernel.org\$',
          ),
          [],
        );
      });

      test('successfully deletes all values of a multivar when regexp is empty',
          () {
        expect(
          config.multivar(variable: 'core.gitproxy'),
          [
            'proxy-command for kernel.org',
            'default-proxy',
          ],
        );

        config.deleteMultivar(variable: 'core.gitproxy', regexp: '');

        expect(config.multivar(variable: 'core.gitproxy'), []);
      });
    });
  });
}
