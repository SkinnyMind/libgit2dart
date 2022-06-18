import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/packbuilder.dart' as bindings;
import 'package:meta/meta.dart';

class PackBuilder {
  /// Initializes a new instance of [PackBuilder] class.
  ///
  /// Throws a [LibGit2Error] if error occured.
  ///
  /// Note: For internal use.
  @internal
  PackBuilder(Repository repo) {
    _packbuilderPointer = bindings.init(repo.pointer);
    _finalizer.attach(this, _packbuilderPointer, detach: this);
  }

  /// Pointer to memory address for allocated packbuilder object.
  late final Pointer<git_packbuilder> _packbuilderPointer;

  /// Adds a single object.
  ///
  /// For an optimal pack it's mandatory to add objects in recency order,
  /// commits followed by trees and blobs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void add(Oid oid) {
    bindings.add(
      packbuilderPointer: _packbuilderPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Recursively adds an object and its referenced objects.
  ///
  /// Adds the object as well as any object it references.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addRecursively(Oid oid) {
    bindings.addRecursively(
      packbuilderPointer: _packbuilderPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Adds a commit object.
  ///
  /// This will add a commit as well as the completed referenced tree.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addCommit(Oid oid) {
    bindings.addCommit(
      packbuilderPointer: _packbuilderPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Adds a root tree object.
  ///
  /// This will add the tree as well as all referenced trees and blobs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addTree(Oid oid) {
    bindings.addTree(
      packbuilderPointer: _packbuilderPointer,
      oidPointer: oid.pointer,
    );
  }

  /// Adds objects as given by the walker.
  ///
  /// Those commits and all objects they reference will be inserted into the
  /// packbuilder.
  void addWalk(RevWalk walker) {
    bindings.addWalk(
      packbuilderPointer: _packbuilderPointer,
      walkerPointer: walker.pointer,
    );
  }

  /// Writes the new pack and corresponding index file to [path] if provided
  /// or default location.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void write(String? path) {
    bindings.write(packbuilderPointer: _packbuilderPointer, path: path);
  }

  /// Total number of objects the packbuilder will write out.
  int get length => bindings.length(_packbuilderPointer);

  /// Number of objects the packbuilder has already written out.
  int get writtenLength => bindings.writtenCount(_packbuilderPointer);

  /// Unique name for the resulting packfile.
  ///
  /// The packfile's name is derived from the packfile's content. This is only
  /// correct after the packfile has been written.
  String get name => bindings.name(_packbuilderPointer);

  /// Sets and returns the number of threads to spawn.
  ///
  /// By default, libgit2 won't spawn any threads at all. When set to 0,
  /// libgit2 will autodetect the number of CPUs.
  int setThreads(int number) {
    return bindings.setThreads(
      packbuilderPointer: _packbuilderPointer,
      number: number,
    );
  }

  /// Releases memory allocated for packbuilder object.
  void free() {
    bindings.free(_packbuilderPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'PackBuilder{length: $length, writtenLength: $writtenLength}';
  }
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_packbuilder>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
