import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> copyRepo({
  required Directory from,
  required Directory to,
}) async {
  await for (final entity in from.list()) {
    if (entity is Directory) {
      late Directory newDir;
      if (p.basename(entity.path) == '.gitdir') {
        newDir = Directory(p.join(to.absolute.path, '.git'));
      } else {
        newDir = Directory(p.join(to.absolute.path, p.basename(entity.path)));
      }
      await newDir.create();
      await copyRepo(from: entity.absolute, to: newDir);
    } else if (entity is File) {
      if (p.basename(entity.path) == 'gitignore') {
        await entity.copy(p.join(to.path, '.gitignore'));
      } else {
        await entity.copy(p.join(to.path, p.basename(entity.path)));
      }
    }
  }
}
