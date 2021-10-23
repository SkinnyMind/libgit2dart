// ignore_for_file: avoid_print

import 'dart:io';
import 'package:libgit2dart/libgit2dart.dart';
import '../test/helpers/util.dart';

void main() {
  // Preparing example repository.
  final tmpDir = setupRepo(Directory('test/assets/testrepo/'));

  final repo = Repository.open(tmpDir.path);

  // Get list of repo's references.
  print('Repository references: ${repo.references}');

  // Get reference by name.
  final ref = repo.lookupReference('refs/heads/master');

  print('Reference SHA hex: ${ref.target.sha}');
  print('Is reference a local branch: ${ref.isBranch}');
  print('Reference full name: ${ref.name}');
  print('Reference shorthand name: ${ref.shorthand}');

  // Create new reference (direct or symbolic).
  final newRef = repo.createReference(
    name: 'refs/tags/v1',
    target: 'refs/heads/master',
  );

  // Rename reference.
  repo.renameReference(oldName: 'v1', newName: 'refs/tags/v1.1');

  // Delete reference.
  repo.deleteReference('v1.1');

  // free() should be called on object to free memory when done.
  ref.free();
  newRef.free();
  repo.free();

  // Removing example repository.
  tmpDir.deleteSync(recursive: true);
}
