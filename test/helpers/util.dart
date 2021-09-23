import 'dart:io';
import 'package:path/path.dart' as p;

final tmpDir = Directory.systemTemp.createTempSync('testrepo');

Future<Directory> setupRepo(Directory repoDir) async {
  if (await tmpDir.exists()) {
    await tmpDir.delete(recursive: true);
  }
  await copyRepo(from: repoDir, to: await tmpDir.create());
  return tmpDir;
}

Future<void> copyRepo({required Directory from, required Directory to}) async {
  await for (final entity in from.list()) {
    if (entity is Directory) {
      Directory newDir;
      if (p.basename(entity.path) == '.gitdir') {
        newDir = Directory(p.join(to.absolute.path, '.git'));
      } else {
        newDir = Directory(p.join(to.absolute.path, p.basename(entity.path)));
      }
      await copyRepo(from: entity.absolute, to: await newDir.create());
    } else if (entity is File) {
      if (p.basename(entity.path) == 'gitignore') {
        await entity.copy(p.join(to.path, '.gitignore'));
      } else {
        await entity.copy(p.join(to.path, p.basename(entity.path)));
      }
    }
  }
}
