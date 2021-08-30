import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/signature.dart' as bindings;
import 'util.dart';

class Signature {
  /// Initializes a new instance of [Signature] class from provided pointer to
  /// signature object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Signature(this._signaturePointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Signature] class from provided [name], [email],
  /// and optional [time] in seconds from epoch and [offset] in minutes.
  ///
  /// If [time] isn't provided [Signature] will be created with a timestamp of 'now'.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Signature.create({
    required String name,
    required String email,
    int? time,
    int offset = 0,
  }) {
    libgit2.git_libgit2_init();

    if (time == null) {
      _signaturePointer = bindings.now(name, email);
    } else {
      _signaturePointer = bindings.create(name, email, time, offset);
    }
  }

  late final Pointer<git_signature> _signaturePointer;

  /// Pointer to memory address for allocated signature object.
  Pointer<git_signature> get pointer => _signaturePointer;

  /// Returns full name of the author.
  String get name => _signaturePointer.ref.name.cast<Utf8>().toDartString();

  /// Returns email of the author.
  String get email => _signaturePointer.ref.email.cast<Utf8>().toDartString();

  /// Returns time in seconds from epoch.
  int get time => _signaturePointer.ref.when.time;

  /// Returns timezone offset in minutes.
  int get offset => _signaturePointer.ref.when.offset;

  @override
  bool operator ==(other) {
    return (other is Signature) &&
        (name == other.name) &&
        (email == other.email) &&
        (time == other.time) &&
        (offset == other.offset) &&
        (_signaturePointer.ref.when.sign ==
            other._signaturePointer.ref.when.sign);
  }

  @override
  int get hashCode => _signaturePointer.address.hashCode;

  /// Releases memory allocated for signature object.
  void free() {
    bindings.free(_signaturePointer);
  }
}
