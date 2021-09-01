import 'dart:ffi';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Get the object type of an object.
int type(Pointer<git_object> obj) => libgit2.git_object_type(obj);
