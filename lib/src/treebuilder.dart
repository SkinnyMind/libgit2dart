import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/treebuilder.dart' as bindings;

class TreeBuilder {
  /// Initializes a new instance of [TreeBuilder] class from provided
  /// [repo]sitory and optional [tree] objects.
  ///
  /// Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  TreeBuilder({required Repository repo, Tree? tree}) {
    _treeBuilderPointer = bindings.create(
      repoPointer: repo.pointer,
      sourcePointer: tree?.pointer ?? nullptr,
    );
  }

  late final Pointer<git_treebuilder> _treeBuilderPointer;

  /// Pointer to memory address for allocated tree builder object.
  Pointer<git_treebuilder> get pointer => _treeBuilderPointer;

  /// Returns the number of entries listed in a tree builder.
  int get length => bindings.entryCount(_treeBuilderPointer);

  /// Writes the contents of the tree builder as a tree object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid write() => Oid(bindings.write(_treeBuilderPointer));

  /// Clears all the entires in the tree builder.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void clear() => bindings.clear(_treeBuilderPointer);

  /// Returns an entry from the tree builder from its filename.
  ///
  /// The returned entry is owned by the tree builder and should not be freed manually.
  ///
  /// Throws [ArgumentError] if nothing found for provided filename.
  TreeEntry operator [](String filename) {
    return TreeEntry(bindings.getByFilename(
      builderPointer: _treeBuilderPointer,
      filename: filename,
    ));
  }

  /// Adds or updates an entry to the tree builder with the given attributes.
  ///
  /// If an entry named filename already exists, its attributes will be updated with
  /// the given ones.
  ///
  /// By default the entry that you are inserting will be checked for validity;
  /// that it exists in the object database and is of the correct type.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void add({
    required String filename,
    required Oid oid,
    required GitFilemode filemode,
  }) {
    bindings.add(
      builderPointer: _treeBuilderPointer,
      filename: filename,
      oidPointer: oid.pointer,
      filemode: filemode.value,
    );
  }

  /// Removes an entry from the tree builder by its filename.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove(String filename) {
    bindings.remove(
      builderPointer: _treeBuilderPointer,
      filename: filename,
    );
  }

  /// Releases memory allocated for tree builder object and all the entries.
  void free() => bindings.free(_treeBuilderPointer);
}
