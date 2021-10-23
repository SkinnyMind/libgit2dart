import 'dart:ffi';

import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/util.dart';

/// Suggests that the given refdb compress or optimize its references.
/// This mechanism is implementation specific. For on-disk reference databases,
/// for example, this may pack all loose references.
void compress(Pointer<git_refdb> refdb) => libgit2.git_refdb_compress(refdb);

/// Close an open reference database to release memory.
void free(Pointer<git_refdb> refdb) => libgit2.git_refdb_free(refdb);
