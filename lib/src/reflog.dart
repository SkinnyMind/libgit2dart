import 'dart:collection';
import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/reflog.dart' as bindings;

class RefLog with IterableMixin<RefLogEntry> {
  /// Initializes a new instance of [RefLog] class from provided [Reference].
  RefLog(Reference ref) {
    _reflogPointer = bindings.read(
      repoPointer: ref.owner.pointer,
      name: ref.name,
    );
  }

  /// Pointer to memory address for allocated reflog object.
  late final Pointer<git_reflog> _reflogPointer;

  /// Lookup an entry by its index.
  ///
  /// Requesting the reflog entry with an index of 0 (zero) will return
  /// the most recently created entry.
  RefLogEntry operator [](int index) {
    return RefLogEntry(bindings.getByIndex(
      reflogPointer: _reflogPointer,
      index: index,
    ));
  }

  /// Releases memory allocated for reflog object.
  void free() => bindings.free(_reflogPointer);

  @override
  Iterator<RefLogEntry> get iterator => _RefLogIterator(_reflogPointer);
}

class RefLogEntry {
  /// Initializes a new instance of [RefLogEntry] class.
  const RefLogEntry(this._entryPointer);

  /// Pointer to memory address for allocated reflog entry object.
  final Pointer<git_reflog_entry> _entryPointer;

  /// Returns the log message.
  String get message => bindings.entryMessage(_entryPointer);

  /// Returns the committer of this entry.
  Signature get committer => Signature(bindings.entryCommiter(_entryPointer));

  @override
  String toString() => 'RefLogEntry{message: $message, committer: $committer}';
}

class _RefLogIterator implements Iterator<RefLogEntry> {
  _RefLogIterator(this._reflogPointer) {
    _count = bindings.entryCount(_reflogPointer);
  }

  /// Pointer to memory address for allocated reflog object.
  final Pointer<git_reflog> _reflogPointer;

  RefLogEntry? _currentEntry;
  int _index = 0;
  late final int _count;

  @override
  RefLogEntry get current => _currentEntry!;

  @override
  bool moveNext() {
    if (_index == _count) {
      return false;
    } else {
      _currentEntry = RefLogEntry(bindings.getByIndex(
        reflogPointer: _reflogPointer,
        index: _index,
      ));
      _index++;
      return true;
    }
  }
}
