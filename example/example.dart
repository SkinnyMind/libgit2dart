import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repo = Repository.open(Directory.current.path);
  print(repo.path);

  stdout.write(repo.headCommit);
}
