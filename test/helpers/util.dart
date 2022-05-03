import 'dart:io';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;

/// Copies repository at provided [repoDir] into system's temp directory.
Directory setupRepo(Directory repoDir) {
  Libgit2.ownerValidation = false;
  final tmpDir = Directory.systemTemp.createTempSync('testrepo');
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
      } else if (p.basename(entity.path) == 'gitattributes') {
        entity.copySync(p.join(to.path, '.gitattributes'));
      } else {
        entity.copySync(p.join(to.path, p.basename(entity.path)));
      }
    }
  }
}
