import 'dart:io';
import 'package:path/path.dart' as p;

Directory setupRepo(Directory repoDir) {
  final tmpDir = Directory.systemTemp.createTempSync('testrepo');
  if (tmpDir.existsSync()) {
    tmpDir.deleteSync(recursive: true);
  }
  tmpDir.createSync();
  copyRepo(from: repoDir, to: tmpDir);
  return tmpDir;
}

void copyRepo({required Directory from, required Directory to}) {
  for (final entity in from.listSync()) {
    if (entity is Directory) {
      Directory newDir;
      if (p.basename(entity.path) == '.gitdir') {
        newDir = Directory(p.join(to.absolute.path, '.git'))..createSync();
      } else {
        newDir = Directory(p.join(to.absolute.path, p.basename(entity.path)))
          ..createSync();
      }
      copyRepo(from: entity.absolute, to: newDir);
    } else if (entity is File) {
      if (p.basename(entity.path) == 'gitignore') {
        entity.copySync(p.join(to.path, '.gitignore'));
      } else {
        entity.copySync(p.join(to.path, p.basename(entity.path)));
      }
    }
  }
}
