import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reflog.dart' as bindings;
import 'reference.dart';
import 'signature.dart';
import 'util.dart';

class RefLog {
  /// Initializes a new instance of [RefLog] class from provided [Reference].
  ///
  /// Throws a [LibGit2Error] if error occured.
  RefLog(Reference ref) {
    libgit2.git_libgit2_init();

    final repo = ref.owner;
    final name = ref.name;
    _reflogPointer = bindings.read(repo.pointer, name);
  }

  /// Pointer to memory address for allocated reflog object.
  late final Pointer<git_reflog> _reflogPointer;

  /// Returns a list with entries of reference log.
  List<RefLogEntry> get entries {
    var log = <RefLogEntry>[];

    for (var i = 0; i < count; i++) {
      log.add(RefLogEntry(bindings.getByIndex(_reflogPointer, i)));
    }

    return log;
  }

  /// Returns the number of log entries in a reflog.
  int get count => bindings.entryCount(_reflogPointer);

  /// Lookup an entry by its index.
  ///
  /// Requesting the reflog entry with an index of 0 (zero) will return
  /// the most recently created entry.
  RefLogEntry operator [](int index) {
    return RefLogEntry(bindings.getByIndex(_reflogPointer, index));
  }

  /// Releases memory allocated for reflog object.
  void free() => bindings.free(_reflogPointer);
}

class RefLogEntry {
  /// Initializes a new instance of [RefLogEntry] class.
  RefLogEntry(this._entryPointer);

  /// Pointer to memory address for allocated reflog entry object.
  late final Pointer<git_reflog_entry> _entryPointer;

  /// Returns the log message.
  String get message => bindings.entryMessage(_entryPointer);

  /// Returns the committer of this entry.
  Signature get committer => Signature(bindings.entryCommiter(_entryPointer));
}
