import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

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

  const expectedEntries = [
    'core.repositoryformatversion',
    'core.bare',
    'core.gitproxy',
    'core.gitproxy',
    'remote.origin.url',
  ];

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
    test('successfully opens file with provided path', () {
      expect(config, isA<Config>());
    });

    test(
        'opens the global, XDG and system configuration files '
        '(if they are present) if no path provided', () {
      try {
        final config = Config.open();
        expect(config, isA<Config>());
        config.free();
      } catch (e) {
        expect(() => Config.open(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('throws when trying to open non existing file', () {
      expect(
        () => Config.open('not.there'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'error',
            "Exception: File not found",
          ),
        ),
      );
    });

    test('successfully opens system file or throws is there is none', () {
      try {
        final config = Config.system();
        expect(config, isA<Config>());
        config.free();
      } catch (e) {
        expect(() => Config.system(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('successfully opens global file or throws is there is none', () {
      try {
        final config = Config.global();
        expect(config, isA<Config>());
        config.free();
      } catch (e) {
        expect(() => Config.global(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('successfully opens xdg file or throws is there is none', () {
      try {
        final config = Config.xdg();
        expect(config, isA<Config>());
        config.free();
      } catch (e) {
        expect(() => Config.xdg(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('returns config snapshot', () {
      final snapshot = config.snapshot;
      expect(snapshot, isA<Config>());
      snapshot.free();
    });

    test('returns config entries and their values', () {
      var i = 0;
      for (final entry in config) {
        expect(entry.name, expectedEntries[i]);
        expect(entry.includeDepth, 0);
        expect(entry.level, GitConfigLevel.local);
        entry.free();
        i++;
      }
    });

    group('get value', () {
      test('returns value of variable', () {
        expect(config['core.bare'].value, 'false');
      });

      test('throws when variable isn\'t found', () {
        expect(
          () => config['not.there'],
          throwsA(
            isA<LibGit2Error>().having(
              (e) => e.toString(),
              'error',
              "config value 'not.there' was not found",
            ),
          ),
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

      test('throws when trying to set invalid value', () {
        expect(
          () => config['remote.origin.url'] = 0.1,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'error',
              'Invalid argument: "0.1 must be either bool, int or String"',
            ),
          ),
        );
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

    test('returns string representation of ConfigEntry object', () {
      final entry = config.first;
      expect(entry.toString(), contains('ConfigEntry{'));
      entry.free();
    });
  });
}
