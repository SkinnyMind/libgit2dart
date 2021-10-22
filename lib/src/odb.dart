import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/odb.dart' as bindings;
import 'util.dart';

class Odb {
  /// Initializes a new instance of [Odb] class from provided
  /// pointer to Odb object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Odb(this._odbPointer);

  /// Creates a new object database with no backends.
  ///
  /// Before the ODB can be used for read/writing, a custom database backend must be
  /// manually added.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Odb.create() {
    libgit2.git_libgit2_init();

    _odbPointer = bindings.create();
  }

  late final Pointer<git_odb> _odbPointer;

  /// Pointer to memory address for allocated oid object.
  Pointer<git_odb> get pointer => _odbPointer;

  /// Adds an on-disk alternate to an existing Object DB.
  ///
  /// Note that the added [path] must point to an `objects`, not to a full repository,
  /// to use it as an alternate store.
  ///
  /// Alternate backends are always checked for objects after all the main backends
  /// have been exhausted.
  ///
  /// Writing is disabled on alternate backends.
  void addDiskAlternate(String path) {
    bindings.addDiskAlternate(
      odbPointer: _odbPointer,
      path: path,
    );
  }

  /// List of all objects [Oid]s available in the database.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Oid> get objects => bindings.objects(_odbPointer);

  /// Whether given object [oid] can be found in the object database.
  bool contains(Oid oid) {
    return bindings.exists(odbPointer: _odbPointer, oidPointer: oid.pointer);
  }

  /// Reads an object from the database.
  ///
  /// This method queries all available ODB backends trying to read the given [oid].
  ///
  /// **IMPORTANT**: Returned object should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  OdbObject read(Oid oid) {
    return OdbObject(bindings.read(
      odbPointer: _odbPointer,
      oidPointer: oid.pointer,
    ));
  }

  /// Writes raw [data] to into the object database.
  ///
  /// [type] should be one of [GitObject.blob], [GitObject.commit], [GitObject.tag] or
  /// [GitObject.tree].
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if provided type is invalid.
  Oid write({required GitObject type, required String data}) {
    if (type == GitObject.any ||
        type == GitObject.invalid ||
        type == GitObject.offsetDelta ||
        type == GitObject.refDelta) {
      throw ArgumentError.value('$type is invalid type');
    } else {
      return Oid(bindings.write(
        odbPointer: _odbPointer,
        type: type.value,
        data: data,
      ));
    }
  }

  /// Releases memory allocated for odb object.
  void free() => bindings.free(_odbPointer);
}

class OdbObject {
  /// Initializes a new instance of the [OdbObject] class from
  /// provided pointer to odbObject object in memory.
  const OdbObject(this._odbObjectPointer);

  /// Pointer to memory address for allocated odbObject object.
  final Pointer<git_odb_object> _odbObjectPointer;

  /// [Oid] of an ODB object.
  Oid get oid => Oid(bindings.objectId(_odbObjectPointer));

  /// Type of an ODB object.
  GitObject get type {
    final typeInt = bindings.objectType(_odbObjectPointer);
    return GitObject.values.singleWhere((e) => typeInt == e.value);
  }

  /// Uncompressed, raw data as read from the ODB, without the leading header.
  String get data => bindings.objectData(_odbObjectPointer);

  /// Real size of the `data` buffer, not the actual size of the object.
  int get size => bindings.objectSize(_odbObjectPointer);

  /// Releases memory allocated for odbObject object.
  void free() => bindings.objectFree(_odbObjectPointer);

  @override
  String toString() {
    return 'OdbObject{oid: $oid, type: $type, size: $size}';
  }
}
