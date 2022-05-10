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
    tag = Tag.lookup(repo: repo, oid: tagOid);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Tag', () {
    test('initializes tag from provided sha', () {
      expect(tag, isA<Tag>());
    });

    test('throws when trying to lookup tag for invalid oid', () {
      expect(
        () => Tag.lookup(repo: repo, oid: repo['0' * 40]),
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

      expect(tag.oid, tagOid);
      expect(tag.name, 'v0.2');
      expect(tag.message, 'annotated tag\n');
      expect(tag.targetType, GitObject.commit);
      expect(target.message, 'add subdirectory file\n');
      expect(tag.tagger, signature);
      expect(tag.toString(), contains('Tag{'));
    });

    test('creates new annotated tag with commit as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      const targetSHA = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
      final target = repo[targetSHA];
      const message = 'init tag\n';

      final oid = Tag.createAnnotated(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        tagger: signature,
        message: message,
      );

      final newTag = Tag.lookup(repo: repo, oid: oid);
      final newTagTarget = newTag.target as Commit;

      expect(newTag.oid, oid);
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.targetOid.sha, targetSHA);
      expect(newTag.tagger, signature);
      expect(newTagTarget.oid, target);
    });

    test('creates new lightweight tag with commit as target', () {
      const tagName = 'tag';
      final target = repo['f17d0d48eae3aa08cecf29128a35e310c97b3521'];

      Tag.createLightweight(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
      );

      final newTag = Reference.lookup(repo: repo, name: 'refs/tags/$tagName');

      expect(newTag.shorthand, tagName);
      expect(newTag.target, target);
    });

    test('creates new annotated tag with tree as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f'];
      const message = 'init tag\n';

      final oid = Tag.createAnnotated(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.tree,
        tagger: signature,
        message: message,
      );

      final newTag = Tag.lookup(repo: repo, oid: oid);
      final newTagTarget = newTag.target as Tree;

      expect(newTag.oid, oid);
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.tagger, signature);
      expect(newTagTarget.oid, target);
    });

    test('creates new lightweight tag with tree as target', () {
      const tagName = 'tag';
      final target = repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f'];

      Tag.createLightweight(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.tree,
      );

      final newTag = Reference.lookup(repo: repo, name: 'refs/tags/$tagName');

      expect(newTag.shorthand, tagName);
      expect(newTag.target, target);
    });

    test('creates new annotated tag with blob as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'];
      const message = 'init tag\n';

      final oid = Tag.createAnnotated(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.blob,
        tagger: signature,
        message: message,
      );

      final newTag = Tag.lookup(repo: repo, oid: oid);
      final newTagTarget = newTag.target as Blob;

      expect(newTag.oid, oid);
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.tagger, signature);
      expect(newTagTarget.oid, target);
    });

    test('creates new lightweight tag with blob as target', () {
      const tagName = 'tag';
      final target = repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'];

      Tag.createLightweight(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.blob,
      );

      final newTag = Reference.lookup(repo: repo, name: 'refs/tags/$tagName');

      expect(newTag.shorthand, tagName);
      expect(newTag.target, target);
    });

    test('creates new annotated tag with tag as target', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      const message = 'init tag\n';

      final oid = Tag.createAnnotated(
        repo: repo,
        tagName: tagName,
        target: tag.oid,
        targetType: GitObject.tag,
        tagger: signature,
        message: message,
      );

      final newTag = Tag.lookup(repo: repo, oid: oid);
      final newTagTarget = newTag.target as Tag;

      expect(newTag.oid, oid);
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.tagger, signature);
      expect(newTagTarget.oid, tag.oid);
    });

    test('creates new lightweight tag with tag as target', () {
      const tagName = 'tag';

      Tag.createLightweight(
        repo: repo,
        tagName: tagName,
        target: tag.oid,
        targetType: GitObject.tag,
      );

      final newTag = Reference.lookup(repo: repo, name: 'refs/tags/$tagName');

      expect(newTag.shorthand, tagName);
      expect(newTag.target, tag.oid);
    });

    test(
        'creates new annotated tag with already existing name '
        'when force is set to true', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final tagName = tag.name;
      const targetSHA = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
      final target = repo[targetSHA];
      const message = 'init tag\n';

      expect(tag.targetOid.sha, isNot(targetSHA));
      expect(repo.tags.length, equals(2));

      final oid = Tag.createAnnotated(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        tagger: signature,
        message: message,
        force: true,
      );

      final newTag = Tag.lookup(repo: repo, oid: oid);
      final newTagTarget = newTag.target as Commit;

      expect(newTag.oid, oid);
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(newTag.targetOid.sha, targetSHA);
      expect(newTag.tagger, signature);
      expect(newTagTarget.oid, target);
      expect(repo.tags.length, equals(2));
    });

    test(
        'creates new lightweight tag with already existing name '
        'when force is set to true', () {
      final tagName = tag.name;
      const targetSHA = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
      final target = repo[targetSHA];

      expect(tag.targetOid.sha, isNot(targetSHA));
      expect(repo.tags.length, equals(2));

      Tag.createLightweight(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        force: true,
      );

      final newTag = Reference.lookup(repo: repo, name: 'refs/tags/$tagName');

      expect(newTag.shorthand, tagName);
      expect(newTag.target, target);
      expect(repo.tags.length, equals(2));
    });

    test('throws when trying to create annotated tag with invalid name', () {
      expect(
        () => Tag.createAnnotated(
          repo: repo,
          tagName: '',
          target: repo['9c78c21'],
          targetType: GitObject.any,
          tagger: Signature(nullptr),
          message: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to create lightweight tag with invalid name', () {
      expect(
        () => Tag.createLightweight(
          repo: repo,
          tagName: '',
          target: repo['9c78c21'],
          targetType: GitObject.any,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to create annotated tag with invalid target', () {
      expect(
        () => Tag.createAnnotated(
          repo: repo,
          tagName: '',
          target: repo['0' * 40],
          targetType: GitObject.commit,
          tagger: Signature(nullptr),
          message: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to create lightweight tag with invalid target',
        () {
      expect(
        () => Tag.createLightweight(
          repo: repo,
          tagName: '',
          target: repo['0' * 40],
          targetType: GitObject.commit,
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
      expect(Tag.list(repo), ['v0.1', 'v0.2']);

      Tag.delete(repo: repo, name: 'v0.2');
      expect(Tag.list(repo), ['v0.1']);
    });

    test('throws when trying to delete non existing tag', () {
      expect(
        () => Tag.delete(repo: repo, name: 'not.there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      tag = Tag.lookup(repo: repo, oid: tagOid);
      expect(() => tag.free(), returnsNormally);
    });

    test('supports value comparison', () {
      expect(
        Tag.lookup(repo: repo, oid: tagOid),
        equals(Tag.lookup(repo: repo, oid: tagOid)),
      );
    });
  });
}
