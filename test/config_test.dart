import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final filePath = p.join(Directory.systemTemp.path, 'test_config');
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
    File(filePath).writeAsStringSync(contents);
    config = Config.open(filePath);
  });

  tearDown(() {
    File(filePath).deleteSync();
  });

  group('Config', () {
    test('opens file with provided path', () {
      expect(config, isA<Config>());
    });

    test(
        'opens the global, XDG and system configuration files '
        '(if they are present) if no path provided', () {
      try {
        expect(Config.open(), isA<Config>());
      } catch (e) {
        expect(() => Config.open(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('throws when trying to open non existing file', () {
      expect(() => Config.open('not.there'), throwsA(isA<Exception>()));
    });

    test('opens system file or throws is there is none', () {
      try {
        expect(Config.system(), isA<Config>());
      } catch (e) {
        expect(() => Config.system(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('opens global file or throws is there is none', () {
      try {
        expect(Config.global(), isA<Config>());
      } catch (e) {
        expect(() => Config.global(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('opens xdg file or throws is there is none', () {
      try {
        expect(Config.xdg(), isA<Config>());
      } catch (e) {
        expect(() => Config.xdg(), throwsA(isA<LibGit2Error>()));
      }
    });

    test('returns config snapshot', () {
      expect(config.snapshot, isA<Config>());
    });

    test('returns config entries and their values', () {
      var i = 0;
      for (final entry in config) {
        expect(entry.name, expectedEntries[i]);
        expect(entry.includeDepth, 0);
        expect(entry.level, GitConfigLevel.local);
        i++;
      }
    });

    group('get value', () {
      test('returns value of variable', () {
        expect(config['core.bare'].value, 'false');
      });

      test("throws when variable isn't found", () {
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

      test('throws when trying to set invalid value', () {
        expect(
          () => config['remote.origin.url'] = 0.1,
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('delete', () {
      test('deletes entry', () {
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
            regexp: r'for kernel.org$',
          ),
          ['proxy-command for kernel.org'],
        );
      });

      test('returns empty list if multivar not found', () {
        expect(config.multivar(variable: 'not.there'), <String>[]);
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
    });

    group('deleteMultivar()', () {
      test('deletes value of a multivar', () {
        expect(
          config.multivar(
            variable: 'core.gitproxy',
            regexp: r'for kernel.org$',
          ),
          ['proxy-command for kernel.org'],
        );

        config.deleteMultivar(
          variable: 'core.gitproxy',
          regexp: r'for kernel.org$',
        );

        expect(
          config.multivar(
            variable: 'core.gitproxy',
            regexp: r'for kernel.org$',
          ),
          <String>[],
        );
      });
    });

    test('manually releases allocated memory', () {
      final config = Config.open(filePath);
      expect(() => config.free(), returnsNormally);
    });

    test('returns string representation of ConfigEntry object', () {
      final entry = config.first;
      expect(entry.toString(), contains('ConfigEntry{'));
    });

    test('supports value comparison', () {
      expect(Config.open(filePath), equals(Config.open(filePath)));
    });
  });
}
