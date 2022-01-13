import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tag tag;
  late Directory tmpDir;
  late Oid tagOid;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    tagOid = repo['f0fdbf506397e9f58c59b88dfdd72778ec06cc0c'];
    tag = repo.lookupTag(tagOid);
  });

  tearDown(() {
    tag.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Tag', () {
    test('initializes tag from provided sha', () {
      expect(tag, isA<Tag>());
    });

    test('throws when trying to lookup tag for invalid oid', () {
      expect(
        () => repo.lookupTag(repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to get target of a tag and error occurs', () {
      expect(() => Tag(nullptr).target, throwsA(isA<LibGit2Error>()));
    });

    test('returns correct values', () {
      final signature = Signature.create(
        name: 'Aleksey Kulikov',
        email: 'skinny.mind@gmail.com',
        time: 1630599723,
        offset: 180,
      );
      final target = tag.target as Commit;
      final tagger = tag.tagger;

      expect(tag.oid, tagOid);
      expect(tag.name, 'v0.2');
      expect(tag.message, 'annotated tag\n');
      expect(target.message, 'add subdirectory file\n');
      expect(tagger, signature);
      expect(tag.toString(), contains('Tag{'));

      signature.free();
      target.free();
    });

    test('creates new tag with commit as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      const targetSHA = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
      final target = repo[targetSHA];
      const message = 'init tag\n';

      final oid = repo.createTag(
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        tagger: signature,
        message: message,
      );

      final newTag = repo.lookupTag(oid);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Commit;

      expect(newTag.oid.sha, '131a5eb6b7a880b5096c550ee7351aeae7b95a42');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.targetOid.sha, targetSHA);
      expect(tagger, signature);
      expect(newTagTarget.oid, target);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('creates new tag with tree as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f'];
      const message = 'init tag\n';

      final oid = repo.createTag(
        tagName: tagName,
        target: target,
        targetType: GitObject.tree,
        tagger: signature,
        message: message,
      );

      final newTag = repo.lookupTag(oid);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Tree;

      expect(newTag.oid.sha, 'ca715c0bafad5d39d568675aad69f71a82178416');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(tagger, signature);
      expect(newTagTarget.oid, target);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('creates new tag with blob as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'];
      const message = 'init tag\n';

      final oid = repo.createTag(
        tagName: tagName,
        target: target,
        targetType: GitObject.blob,
        tagger: signature,
        message: message,
      );

      final newTag = repo.lookupTag(oid);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Blob;

      expect(newTag.oid.sha, '8b1edabda95e934d2252e563219315b08e38dce5');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(tagger, signature);
      expect(newTagTarget.oid, target);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('creates new tag with tag as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      const message = 'init tag\n';

      final oid = repo.createTag(
        tagName: tagName,
        target: tag.oid,
        targetType: GitObject.tag,
        tagger: signature,
        message: message,
      );

      final newTag = repo.lookupTag(oid);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Tag;

      expect(newTag.oid.sha, '20286cf6c3b150b58b6c419814b0931d9b17c2ba');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(tagger, signature);
      expect(newTagTarget.oid, tag.oid);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('throws when trying to create tag with invalid name', () {
      expect(
        () => repo.createTag(
          tagName: '',
          target: repo['9c78c21'],
          targetType: GitObject.any,
          tagger: Signature(nullptr),
          message: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to create tag with invalid target', () {
      expect(
        () => repo.createTag(
          tagName: '',
          target: repo['0' * 40],
          targetType: GitObject.any,
          tagger: Signature(nullptr),
          message: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns list of tags in repository', () {
      expect(Tag.list(repo), ['v0.1', 'v0.2']);
    });

    test('throws when trying to get list of tags and error occurs', () {
      expect(() => Repository(nullptr).tags, throwsA(isA<LibGit2Error>()));
    });

    test('deletes tag', () {
      expect(repo.tags, ['v0.1', 'v0.2']);

      repo.deleteTag('v0.2');
      expect(repo.tags, ['v0.1']);
    });

    test('throws when trying to delete non existing tag', () {
      expect(() => repo.deleteTag('not.there'), throwsA(isA<LibGit2Error>()));
    });
  });
}
