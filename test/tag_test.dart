import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tag tag;
  late Directory tmpDir;
  const tagSHA = 'f0fdbf506397e9f58c59b88dfdd72778ec06cc0c';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    tag = Tag.lookup(repo: repo, sha: tagSHA);
  });

  tearDown(() async {
    tag.free();
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Tag', () {
    test('successfully initializes tag from provided sha', () {
      expect(tag, isA<Tag>());
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

      expect(tag.id.sha, tagSHA);
      expect(tag.name, 'v0.2');
      expect(tag.message, 'annotated tag\n');
      expect(target.message, 'add subdirectory file\n');
      expect(tagger, signature);

      signature.free();
      target.free();
    });

    test('successfully creates new tag', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      const tagName = 'tag';
      final target = 'f17d0d48eae3aa08cecf29128a35e310c97b3521';
      const message = 'init tag\n';

      final oid = Tag.create(
        repo: repo,
        tagName: tagName,
        target: target,
        targetType: GitObject.commit,
        tagger: signature,
        message: message,
      );

      final newTag = Tag.lookup(repo: repo, sha: oid.sha);
      final tagger = newTag.tagger;
      final newTagTarget = newTag.target as Commit;

      expect(newTag.id.sha, '131a5eb6b7a880b5096c550ee7351aeae7b95a42');
      expect(newTag.name, tagName);
      expect(newTag.message, message);
      expect(tagger, signature);
      expect(newTagTarget.id.sha, target);

      newTag.free();
      newTagTarget.free();
      signature.free();
    });

    test('returns list of tags in repository', () {
      expect(Tag.list(repo), ['v0.1', 'v0.2']);
    });

    test('successfully deletes tag', () {
      expect(repo.tags, ['v0.1', 'v0.2']);

      tag.delete();
      expect(repo.tags, ['v0.1']);
    });
  });
}
