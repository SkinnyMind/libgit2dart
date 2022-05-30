// coverage:ignore-file

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';

extension IsValidSHA on String {
  bool isValidSHA() {
    final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
    return hexRegExp.hasMatch(this) &&
        (GIT_OID_MINPREFIXLEN <= length && GIT_OID_HEXSZ >= length);
  }
}

extension ToChar on String {
  /// Creates a zero-terminated [Utf8] code-unit array from this String,
  /// casts it to the C `char` type and returns allocated pointer to result.
  Pointer<Char> toChar() => toNativeUtf8().cast<Char>();
}

extension ToDartString on Pointer<Char> {
  /// Converts this UTF-8 encoded string to a Dart string.
  ///
  /// Decodes the UTF-8 code units of this zero-terminated byte array as
  /// Unicode code points and creates a Dart string containing those code
  /// points.
  ///
  /// If [length] is provided, zero-termination is ignored and the result can
  /// contain NUL characters.
  ///
  /// If [length] is not provided, the returned string is the string up til but
  /// not including the first NUL character.
  String toDartString({int? length}) =>
      cast<Utf8>().toDartString(length: length);
}
