import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repo = Repository.open(Directory.current.path);
  final ref = repo.getReference('refs/heads/master');

  print('Reference SHA hex: ${ref.target.sha}');
  print('Is reference a local branch: ${ref.isBranch}');
  print('Reference full name: ${ref.name}');

  ref.free();
  repo.free();
}
