import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repo = Repository.open(Directory.current.path);

  print('Repository references: ${repo.references.list()}');

  final ref = repo.references['refs/heads/master'];

  print('Reference SHA hex: ${ref.target.sha}');
  print('Is reference a local branch: ${ref.isBranch}');
  print('Reference full name: ${ref.name}');

  ref.free();
  repo.free();
}
