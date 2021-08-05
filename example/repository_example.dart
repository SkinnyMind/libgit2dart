import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  // Open repository
  try {
    final repo = Repository.open(Directory.current.path);

    print('Path to git repository: ${repo.path}');
    print('Is repository bare: ${repo.isBare}');
    print('Is repository empty: ${repo.isEmpty}');
    print('Is head detached: ${repo.isHeadDetached}');
    print('Repository refs: ${repo.references}');

    // free() should be called on object to free memory when done.
    repo.free();
  } catch (e) {
    print(e);
  }
}
