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

    _repoPointer = repository.open(dir);
    _head = repository.revParseSingle(_repoPointer.value, 'HEAD^{commit}');
    headCommit = libgit2
        .git_commit_message(_head.value.cast<git_commit>())
        .cast<Utf8>()
        .toDartString();
    path = repository.path(_repoPointer.value);
    namespace = repository.getNamespace(_repoPointer.value);
    isBare = repository.isBare(_repoPointer.value);

    // free up neccessary pointers
    calloc.free(_repoPointer);
    calloc.free(_head);
    libgit2.git_libgit2_shutdown();
  }

  late Pointer<Pointer<git_repository>> _repoPointer;
  late Pointer<Pointer<git_object>> _head;
  late String headCommit;
  late String path;
  late String namespace;
  late bool isBare;
}
