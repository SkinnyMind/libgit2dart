import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reflog.dart' as bindings;
import 'reference.dart';
import 'util.dart';

class RefLog {
  /// Initializes a new instance of [RefLog] class from provided [Reference].
  ///
  /// Throws a [LibGit2Error] if error occured.
  RefLog(Reference ref) {
    libgit2.git_libgit2_init();

    final repo = ref.owner;
    final name = ref.name;
    _reflogPointer = bindings.read(repo, name);
  }

  /// Pointer to memory address for allocated reflog object.
  late final Pointer<git_reflog> _reflogPointer;

  /// Returns the number of log entries in a reflog.
  int get count => bindings.entryCount(_reflogPointer);

  /// Lookup an entry by its index.
  ///
  /// Requesting the reflog entry with an index of 0 (zero) will return
  /// the most recently created entry.
  RefLogEntry entryAt(int index) {
    return RefLogEntry(bindings.entryByIndex(_reflogPointer, index));
  }

  /// Releases memory allocated for reflog object.
  void free() {
    bindings.free(_reflogPointer);
    libgit2.git_libgit2_shutdown();
  }
}

class RefLogEntry {
  /// Initializes a new instance of [RefLogEntry] class.
  RefLogEntry(this._entryPointer);

  /// Pointer to memory address for allocated reflog entry object.
  late final Pointer<git_reflog_entry> _entryPointer;

  /// Returns the log message.
  String get message => bindings.entryMessage(_entryPointer);

  /// Returns the committer of this entry.
  Map<String, String> get committer => bindings.entryCommiter(_entryPointer);
}
