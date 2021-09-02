import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/tree.dart' as bindings;
import 'repository.dart';
import 'oid.dart';
import 'enums.dart';
import 'util.dart';

class Tree {
  /// Initializes a new instance of [Tree] class from provided
  /// pointer to tree object in memory.
  Tree(this._treePointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Tree] class from provided
  /// [Repository] and [Oid] objects.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Tree.lookup(Repository repo, Oid oid) {
    _treePointer = bindings.lookup(repo.pointer, oid.pointer);
  }

  late final Pointer<git_tree> _treePointer;

  /// Pointer to memory address for allocated tree object.
  Pointer<git_tree> get pointer => _treePointer;

  /// Returns a list with tree entries of a tree.
  List<TreeEntry> get entries {
    final entryCount = bindings.entryCount(_treePointer);
    var result = <TreeEntry>[];
    for (var i = 0; i < entryCount; i++) {
      result.add(TreeEntry(bindings.getByIndex(_treePointer, i)));
    }

    return result;
  }

  /// Looksup a tree entry in the tree.
  ///
  /// If integer [value] is provided, lookup is done by entry position in the tree.
  ///
  /// If string [value] is provided, lookup is done by entry filename.
  ///
  /// If provided string [value] is a path to file, lookup is done by path. In that case
  /// returned object should be freed explicitly.
  TreeEntry operator [](Object value) {
    if (value is int) {
      return TreeEntry(bindings.getByIndex(_treePointer, value));
    } else if (value is String && value.contains('/')) {
      return TreeEntry(bindings.getByPath(_treePointer, value));
    } else if (value is String) {
      return TreeEntry(bindings.getByName(_treePointer, value));
    } else {
      throw ArgumentError.value(
          '$value should be either index position, filename or path');
    }
  }

  /// Releases memory allocated for tree object.
  void free() => bindings.free(_treePointer);
}

class TreeEntry {
  /// Initializes a new instance of [TreeEntry] class.
  TreeEntry(this._treeEntryPointer);

  /// Pointer to memory address for allocated tree entry object.
  final Pointer<git_tree_entry> _treeEntryPointer;

  /// Returns the Oid of the object pointed by the entry.
  Oid get id => Oid(bindings.entryId(_treeEntryPointer));

  /// Returns the filename of a tree entry.
  String get name => bindings.entryName(_treeEntryPointer);

  /// Returns the UNIX file attributes of a tree entry.
  GitFilemode get filemode {
    return intToGitFilemode(bindings.entryFilemode(_treeEntryPointer));
  }

  @override
  bool operator ==(other) {
    return (other is TreeEntry) &&
        (bindings.compare(_treeEntryPointer, other._treeEntryPointer) == 0);
  }

  bool operator <(other) {
    return (other is TreeEntry) &&
        (bindings.compare(_treeEntryPointer, other._treeEntryPointer) == -1);
  }

  bool operator <=(other) {
    return (other is TreeEntry) &&
        (bindings.compare(_treeEntryPointer, other._treeEntryPointer) == -1);
  }

  bool operator >(other) {
    return (other is TreeEntry) &&
        (bindings.compare(_treeEntryPointer, other._treeEntryPointer) == 1);
  }

  bool operator >=(other) {
    return (other is TreeEntry) &&
        (bindings.compare(_treeEntryPointer, other._treeEntryPointer) == 1);
  }

  @override
  int get hashCode => _treeEntryPointer.address.hashCode;

  /// Releases memory allocated for tree entry object.
  void free() => bindings.entryFree(_treeEntryPointer);
}
