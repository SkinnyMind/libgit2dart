import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/signature.dart' as bindings;
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

@immutable
class Signature extends Equatable {
  /// Initializes a new instance of [Signature] class from provided pointer to
  /// signature object in memory.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Signature.create]
  /// - [Signature.defaultSignature]
  @internal
  Signature(Pointer<git_signature> pointer) {
    _signaturePointer = bindings.duplicate(pointer);
    _finalizer.attach(this, _signaturePointer, detach: this);
  }

  /// Creates new [Signature] from provided [name], [email], and optional [time]
  /// in seconds from epoch and [offset] in minutes.
  ///
  /// If [time] isn't provided [Signature] will be created with a timestamp of
  /// 'now'.
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
    _finalizer.attach(this, _signaturePointer, detach: this);
  }

  /// Creates a new action signature with default user and now timestamp.
  ///
  /// This looks up the user.name and user.email from the configuration and
  /// uses the current time as the timestamp, and creates a new signature based
  /// on that information.
  Signature.defaultSignature(Repository repo) {
    _signaturePointer = bindings.defaultSignature(repo.pointer);
    _finalizer.attach(this, _signaturePointer, detach: this);
  }

  late final Pointer<git_signature> _signaturePointer;

  /// Pointer to memory address for allocated signature object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_signature> get pointer => _signaturePointer;

  /// Full name of the author.
  String get name => _signaturePointer.ref.name.toDartString();

  /// Email of the author.
  String get email => _signaturePointer.ref.email.toDartString();

  /// Time in seconds from epoch.
  int get time => _signaturePointer.ref.when.time;

  /// Timezone offset in minutes.
  int get offset => _signaturePointer.ref.when.offset;

  /// Indicator for questionable '-0000' offsets in signature.
  String get sign => String.fromCharCode(_signaturePointer.ref.when.sign);

  /// Releases memory allocated for signature object.
  void free() {
    bindings.free(_signaturePointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Signature{name: $name, email: $email, time: $time, '
        'offset: $sign$offset}';
  }

  @override
  List<Object?> get props => [name, email, time, offset, sign];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_signature>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
