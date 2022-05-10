import 'dart:collection';
import 'dart:ffi';
import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/reference.dart' as reference_bindings;
import 'package:libgit2dart/src/bindings/reflog.dart' as bindings;
import 'package:meta/meta.dart';

class RefLog with IterableMixin<RefLogEntry> {
  /// Initializes a new instance of [RefLog] class from provided [Reference].
  RefLog(Reference ref) {
    _reflogPointer = bindings.read(
      repoPointer: reference_bindings.owner(ref.pointer),
      name: ref.name,
    );
    _finalizer.attach(this, _reflogPointer, detach: this);
  }

  /// Pointer to memory address for allocated reflog object.
  late final Pointer<git_reflog> _reflogPointer;

  /// Deletes the reflog for the given reference.
  static void delete(Reference ref) {
    bindings.delete(
      repoPointer: reference_bindings.owner(ref.pointer),
      name: ref.name,
    );
  }

  /// Renames a reflog.
  ///
  /// The reflog to be renamed is expected to already exist.
  ///
  /// The new name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void rename({
    required Repository repo,
    required String oldName,
    required String newName,
  }) {
    bindings.rename(
      repoPointer: repo.pointer,
      oldName: oldName,
      newName: newName,
    );
  }

  /// Lookups an entry by its index.
  ///
  /// Requesting the reflog entry with an index of 0 will return the most
  /// recently created entry.
  RefLogEntry operator [](int index) {
    return RefLogEntry._(
      bindings.getByIndex(
        reflogPointer: _reflogPointer,
        index: index,
      ),
    );
  }

  /// Adds a new entry to the in-memory reflog.
  ///
  /// [oid] is the OID the reference is now pointing to.
  ///
  /// [committer] is the signature of the committer.
  ///
  /// [message] is optional reflog message.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void add({
    required Oid oid,
    required Signature committer,
    String message = '',
  }) {
    bindings.add(
      reflogPointer: _reflogPointer,
      oidPointer: oid.pointer,
      committerPointer: committer.pointer,
      message: message,
    );
  }

  /// Removes an entry from the reflog by its [index].
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove(int index) {
    bindings.remove(reflogPointer: _reflogPointer, index: index);
  }

  /// Writes an existing in-memory reflog object back to disk using an atomic
  /// file lock.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void write() => bindings.write(_reflogPointer);

  /// Releases memory allocated for reflog object.
  void free() {
    bindings.free(_reflogPointer);
    _finalizer.detach(this);
  }

  @override
  Iterator<RefLogEntry> get iterator => _RefLogIterator(_reflogPointer);
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_reflog>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

@immutable
class RefLogEntry extends Equatable {
  /// Initializes a new instance of [RefLogEntry] class from provided
  /// pointer to RefLogEntry object in memory.
  const RefLogEntry._(this._entryPointer);

  /// Pointer to memory address for allocated reflog entry object.
  final Pointer<git_reflog_entry> _entryPointer;

  /// Log message.
  ///
  /// Returns empty string if there is no message.
  String get message => bindings.entryMessage(_entryPointer);

  /// Committer of this entry.
  Signature get committer => Signature(bindings.entryCommiter(_entryPointer));

  /// New oid of entry at this time.
  Oid get newOid => Oid(bindings.entryOidNew(_entryPointer));

  /// Old oid of entry.
  Oid get oldOid => Oid(bindings.entryOidOld(_entryPointer));

  @override
  String toString() => 'RefLogEntry{message: $message, committer: $committer}';

  @override
  List<Object?> get props => [message, committer, newOid, oldOid];
}

class _RefLogIterator implements Iterator<RefLogEntry> {
  _RefLogIterator(this._reflogPointer) {
    _count = bindings.entryCount(_reflogPointer);
  }

  /// Pointer to memory address for allocated reflog object.
  final Pointer<git_reflog> _reflogPointer;

  late RefLogEntry _currentEntry;
  int _index = 0;
  late final int _count;

  @override
  RefLogEntry get current => _currentEntry;

  @override
  bool moveNext() {
    if (_index == _count) {
      return false;
    } else {
      _currentEntry = RefLogEntry._(
        bindings.getByIndex(
          reflogPointer: _reflogPointer,
          index: _index,
        ),
      );
      _index++;
      return true;
    }
  }
}
