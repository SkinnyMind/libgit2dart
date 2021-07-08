import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

void main() {
  // Open repository
  try {
    final repo = Repository.open(Directory.current.path);

    print('Path to git repository: ${repo.path()}');
    print('Is repository bare: ${repo.isBare()}');
    print('Is repository empty: ${repo.isEmpty()}');
    print('Is head detached: ${repo.isHeadDetached()}');
    try {
      print('Prepared message: ${repo.message()}');
    } catch (e) {
      print('Prepared message: $e');
    }

    // close() should be called on object to free memory when done.
    repo.close();
  } catch (e) {
    print(e);
  }
}
