import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'helpers.dart';

void main() async {
  // Preparing example repository.
  final tmpDir = '${Directory.systemTemp.path}/example_repo/';
  await prepareRepo(tmpDir);

  final repo = Repository.open(tmpDir);

  // Get list of repo's references.
  print('Repository references: ${repo.references.list()}');

  // Get reference by name.
  final ref = repo.references['refs/heads/master'];

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
  newRef.rename('refs/tags/v1.1');

  // Delete reference.
  newRef.delete();

  // free() should be called on object to free memory when done.
  ref.free();
  newRef.free();
  repo.free();

  // Removing example repository.
  await disposeRepo(tmpDir);
}
