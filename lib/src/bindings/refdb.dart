import 'dart:ffi';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Suggests that the given refdb compress or optimize its references.
/// This mechanism is implementation specific. For on-disk reference databases,
/// for example, this may pack all loose references.
///
/// Throws a [LibGit2Error] if error occured.
void compress(Pointer<git_refdb> refdb) {
  final error = libgit2.git_refdb_compress(refdb);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Close an open reference database to release memory.
void free(Pointer<git_refdb> refdb) => libgit2.git_refdb_free(refdb);
