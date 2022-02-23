import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/signature.dart' as bindings;
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

@immutable
class Signature {
  /// Initializes a new instance of [Signature] class from provided pointer to
  /// signature object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Signature(this._signaturePointer);

  /// Creates new [Signature] from provided [name], [email], and optional [time]
  /// in seconds from epoch and [offset] in minutes.
  ///
  /// If [time] isn't provided [Signature] will be created with a timestamp of
  /// 'now'.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Signature.create({
    required String name,
    required String email,
    int? time,
    int offset = 0,
  }) {
    libgit2.git_libgit2_init();

    if (time == null) {
      _signaturePointer = bindings.now(name: name, email: email);
    } else {
      _signaturePointer = bindings.create(
        name: name,
        email: email,
        time: time,
        offset: offset,
      );
    }
  }

  /// Creates a new action signature with default user and now timestamp.
  ///
  /// This looks up the user.name and user.email from the configuration and
  /// uses the current time as the timestamp, and creates a new signature based
  /// on that information.
  Signature.defaultSignature(Repository repo) {
    _signaturePointer = bindings.defaultSignature(repo.pointer);
  }

  late final Pointer<git_signature> _signaturePointer;

  /// Pointer to memory address for allocated signature object.
  Pointer<git_signature> get pointer => _signaturePointer;

  /// Full name of the author.
  String get name => _signaturePointer.ref.name.cast<Utf8>().toDartString();

  /// Email of the author.
  String get email => _signaturePointer.ref.email.cast<Utf8>().toDartString();

  /// Time in seconds from epoch.
  int get time => _signaturePointer.ref.when.time;

  /// Timezone offset in minutes.
  int get offset => _signaturePointer.ref.when.offset;

  @override
  bool operator ==(Object other) {
    return (other is Signature) &&
        (name == other.name) &&
        (email == other.email) &&
        (time == other.time) &&
        (offset == other.offset) &&
        (_signaturePointer.ref.when.sign ==
            other._signaturePointer.ref.when.sign);
  }

  /// Releases memory allocated for signature object.
  void free() => bindings.free(_signaturePointer);

  @override // coverage:ignore-line
  int get hashCode =>
      _signaturePointer.address.hashCode; // coverage:ignore-line

  @override
  String toString() {
    return 'Signature{name: $name, email: $email, time: $time, '
        'offset: $offset}';
  }
}
