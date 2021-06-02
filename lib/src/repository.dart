import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/repository.dart' as repository;
import 'util.dart';

/// A Repository is the primary interface into a git repository
class Repository {
  Repository();

  /// Initializes a new instance of the [Repository] class.
  /// For a standard repository, [dir] should either point to the `.git` folder
  /// or to the working directory. For a bare repository, [dir] should directly
  /// point to the repository folder.
  Repository.open(String dir) {
    libgit2.git_libgit2_init();

    final _repoPointer = repository.open(dir);
    path = repository.path(_repoPointer.value);
    namespace = repository.getNamespace(_repoPointer.value);
    isBare = repository.isBare(_repoPointer.value);

    // free up neccessary pointers
    calloc.free(_repoPointer);
    libgit2.git_libgit2_shutdown();
  }

  /// Path to the `.git` folder for normal repositories
  /// or path to the repository itself for bare repositories.
  late String path;
  late String namespace;
  late bool isBare;
}
