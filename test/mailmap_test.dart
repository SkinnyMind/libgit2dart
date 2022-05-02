import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  const testMailmap = """
# Simple Comment line
<cto@company.xx>                       <cto@coompany.xx>
Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
Other Author <other@author.xx>    nick2 <bugs@company.xx>
Other Author <other@author.xx>         <nick2@company.xx>
Phil Hill <phil@company.xx>  # Comment at end of line
<joseph@company.xx>             Joseph <bugs@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
""";

  const testEntries = [
    {
      'realName': null,
      'realEmail': "cto@company.xx",
      'name': null,
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Some Dude",
      'realEmail': "some@dude.xx",
      'name': "nick1",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "nick2",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': null,
      'email': "nick2@company.xx",
    },
    {
      'realName': "Phil Hill",
      'realEmail': null,
      'name': null,
      'email': "phil@company.xx",
    },
    {
      'realName': null,
      'realEmail': "joseph@company.xx",
      'name': "Joseph",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Santa Claus",
      'realEmail': "santa.claus@northpole.xx",
      'name': null,
      'email': "me@company.xx",
    },
  ];

  const testResolve = [
    {
      'realName': "Brad",
      'realEmail': "cto@company.xx",
      'name': "Brad",
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Brad L",
      'realEmail': "cto@company.xx",
      'name': "Brad L",
      'email': "cto@coompany.xx",
    },
    {
      'realName': "Some Dude",
      'realEmail': "some@dude.xx",
      'name': "nick1",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "nick2",
      'email': "bugs@company.xx",
    },
    {
      'realName': "nick3",
      'realEmail': "bugs@company.xx",
      'name': "nick3",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Other Author",
      'realEmail': "other@author.xx",
      'name': "Some Garbage",
      'email': "nick2@company.xx",
    },
    {
      'realName': "Phil Hill",
      'realEmail': "phil@company.xx",
      'name': "unknown",
      'email': "phil@company.xx",
    },
    {
      'realName': "Joseph",
      'realEmail': "joseph@company.xx",
      'name': "Joseph",
      'email': "bugs@company.xx",
    },
    {
      'realName': "Santa Claus",
      'realEmail': "santa.claus@northpole.xx",
      'name': "Clause",
      'email': "me@company.xx",
    },
    {
      'realName': "Charles",
      'realEmail': "charles@charles.xx",
      'name': "Charles",
      'email': "charles@charles.xx",
    },
  ];

  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'mailmap_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Mailmap', () {
    test('initializes empty mailmap object', () {
      expect(Mailmap.empty(), isA<Mailmap>());
    });

    test('initializes from provided buffer', () {
      final mailmap = Mailmap.fromBuffer(testMailmap);
      expect(mailmap, isA<Mailmap>());

      for (final entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }
    });

    test('initializes from repository', () {
      final mailmap = Mailmap.fromRepository(repo);
      expect(mailmap, isA<Mailmap>());

      for (final entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }
    });

    test('throws when initializing from repository and error occurs', () {
      expect(
        () => Mailmap.fromRepository(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('resolves names and emails when mailmap is empty', () {
      final mailmap = Mailmap.empty();

      for (final entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['name'], entry['email']],
        );
      }
    });

    test('adds entries and resolves them', () {
      final mailmap = Mailmap.empty();

      for (final entry in testEntries) {
        mailmap.addEntry(
          realName: entry['realName'],
          realEmail: entry['realEmail'],
          replaceName: entry['name'],
          replaceEmail: entry['email']!,
        );
      }

      for (final entry in testResolve) {
        expect(
          mailmap.resolve(name: entry['name']!, email: entry['email']!),
          [entry['realName'], entry['realEmail']],
        );
      }
    });

    test('throws when trying to add entry with empty replace email', () {
      expect(
        () => Mailmap.empty().addEntry(
          replaceEmail: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('resolves signature', () {
      final signature = Signature.create(
        name: 'nick1',
        email: 'bugs@company.xx',
      );
      final realSignature = Signature.create(
        name: 'Some Dude',
        email: 'some@dude.xx',
      );
      final mailmap = Mailmap.empty();
      mailmap.addEntry(
        realName: 'Some Dude',
        realEmail: 'some@dude.xx',
        replaceName: 'nick1',
        replaceEmail: 'bugs@company.xx',
      );

      expect(mailmap.resolveSignature(signature), realSignature);
    });

    test('manually releases allocated memory', () {
      expect(() => Mailmap.empty().free(), returnsNormally);
    });
  });
}
