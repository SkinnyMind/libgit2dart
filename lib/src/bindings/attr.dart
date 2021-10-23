import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/util.dart';

/// Look up the value of one git attribute for path.
///
/// Returned value can be either `true`, `false`, `null` (if the attribute was
/// not set at all), or a [String] value, if the attribute was set to an actual
/// string.
Object? getAttribute({
  required Pointer<git_repository> repoPointer,
  required int flags,
  required String path,
  required String name,
}) {
  final out = calloc<Pointer<Int8>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  libgit2.git_attr_get(out, repoPointer, flags, pathC, nameC);

  calloc.free(pathC);
  calloc.free(nameC);

  final attributeValue = libgit2.git_attr_value(out.value);

  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_UNSPECIFIED) {
    calloc.free(out);
    return null;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_TRUE) {
    calloc.free(out);
    return true;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_FALSE) {
    calloc.free(out);
    return false;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_STRING) {
    final result = out.value.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}
