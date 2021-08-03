import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repo = Repository.open(Directory.current.path);
  final ref = Reference.lookup(repo, 'refs/heads/master');

  print('Reference SHA hex: ${ref.target}');
  print('Is reference a local branch: ${ref.isBranch}');
  print('Reference full name: ${ref.name}');

  ref.free();
}
