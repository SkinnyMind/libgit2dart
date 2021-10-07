import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/packbuilder.dart' as bindings;

class PackBuilder {
  /// Initializes a new instance of [PackBuilder] class.
  ///
  /// Should be freed with `free()`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  PackBuilder(Repository repo) {
    _packbuilderPointer = bindings.init(repo.pointer);
  }

  late final Pointer<git_packbuilder> _packbuilderPointer;

  /// Pointer to memory address for allocated packbuilder object.
  Pointer<git_packbuilder> get pointer => _packbuilderPointer;

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

  /// Writes the new pack and corresponding index file to [path] if provided
  /// or default location.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void write(String? path) {
    bindings.write(packbuilderPointer: _packbuilderPointer, path: path);
  }

  /// Returns the total number of objects the packbuilder will write out.
  int get length => bindings.length(_packbuilderPointer);

  /// Returns the number of objects the packbuilder has already written out.
  int get writtenLength => bindings.writtenCount(_packbuilderPointer);

  /// Sets and returns the number of threads to spawn.
  ///
  /// By default, libgit2 won't spawn any threads at all; when set to 0,
  /// libgit2 will autodetect the number of CPUs.
  int setThreads(int number) {
    return bindings.setThreads(
      packbuilderPointer: _packbuilderPointer,
      number: number,
    );
  }

  /// Releases memory allocated for packbuilder object.
  void free() => bindings.free(_packbuilderPointer);
}
