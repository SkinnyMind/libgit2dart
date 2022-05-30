import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
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
  final out = calloc<Pointer<Char>>();
  final pathC = path.toChar();
  final nameC = name.toChar();
  libgit2.git_attr_get(out, repoPointer, flags, pathC, nameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(pathC);
  calloc.free(nameC);

  final attributeValue = libgit2.git_attr_value(result);

  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_UNSPECIFIED) {
    return null;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_TRUE) {
    return true;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_FALSE) {
    return false;
  }
  if (attributeValue == git_attr_value_t.GIT_ATTR_VALUE_STRING) {
    return result.toDartString();
  }
  return null;
}
