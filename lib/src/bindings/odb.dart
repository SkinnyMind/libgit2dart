import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/oid.dart' as oid_bindings;
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/oid.dart';
import 'package:libgit2dart/src/util.dart';

/// Create a new object database with no backends. The returned odb must be
/// freed with [free].
///
/// Before the ODB can be used for read/writing, a custom database backend must be
/// manually added.
Pointer<git_odb> create() {
  final out = calloc<Pointer<git_odb>>();
  libgit2.git_odb_new(out);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Add an on-disk alternate to an existing Object DB.
///
/// Note that the added path must point to an `objects`, not to a full
/// repository, to use it as an alternate store.
///
/// Alternate backends are always checked for objects after all the main
/// backends have been exhausted.
///
/// Writing is disabled on alternate backends.
void addDiskAlternate({
  required Pointer<git_odb> odbPointer,
  required String path,
}) {
  final pathC = path.toChar();
  libgit2.git_odb_add_disk_alternate(odbPointer, pathC);
  calloc.free(pathC);
}

/// Determine if an object can be found in the object database by an
/// abbreviated object ID.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> existsPrefix({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> shortOidPointer,
  required int length,
}) {
  final out = calloc<git_oid>();
  final error = libgit2.git_odb_exists_prefix(
    out,
    odbPointer,
    shortOidPointer,
    length,
  );

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Determine if the given object can be found in the object database.
bool exists({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  return libgit2.git_odb_exists(odbPointer, oidPointer) == 1 || false;
}

/// List of objects in the database.
///
/// IMPORTANT: make sure to clear that list since it's a global variable.
var _objects = <Oid>[];

/// The callback to call for each object.
int _forEachCb(
  Pointer<git_oid> oid,
  Pointer<Void> payload,
) {
  _objects.add(Oid(oid_bindings.copy(oid)));
  return 0;
}

/// List all objects available in the database.
///
/// Throws a [LibGit2Error] if error occured.
List<Oid> objects(Pointer<git_odb> odb) {
  const except = -1;
  final cb =
      Pointer.fromFunction<Int Function(Pointer<git_oid>, Pointer<Void>)>(
    _forEachCb,
    except,
  );
  final error = libgit2.git_odb_foreach(odb, cb, nullptr);

  if (error < 0) {
    _objects.clear();
    throw LibGit2Error(libgit2.git_error_last());
  }

  final result = _objects.toList(growable: false);
  _objects.clear();

  return result;
}

/// Read an object from the database. The returned object must be freed with
/// [freeObject].
///
/// This method queries all available ODB backends trying to read the given OID.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb_object> read({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_odb_object>>();
  final error = libgit2.git_odb_read(out, odbPointer, oidPointer);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Return the OID of an ODB object.
///
/// This is the OID from which the object was read from.
Pointer<git_oid> objectId(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_id(object);
}

/// Return the type of an ODB object.
int objectType(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_type(object);
}

/// Return the data of an ODB object.
///
/// This is the uncompressed, raw data as read from the ODB, without the
/// leading header.
String objectData(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_data(object).cast<Utf8>().toDartString();
}

/// Return the size of an ODB object.
///
/// This is the real size of the `data` buffer, not the actual size of the
/// object.
int objectSize(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_size(object);
}

/// Write raw data into the object database.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> write({
  required Pointer<git_odb> odbPointer,
  required int type,
  required String data,
}) {
  final stream = calloc<Pointer<git_odb_stream>>();
  final streamError = libgit2.git_odb_open_wstream(
    stream,
    odbPointer,
    data.length,
    type,
  );

  if (streamError < 0) {
    libgit2.git_odb_stream_free(stream.value);
    throw LibGit2Error(libgit2.git_error_last());
  }

  final bufferC = data.toChar();
  libgit2.git_odb_stream_write(stream.value, bufferC, data.length);

  final out = calloc<git_oid>();
  libgit2.git_odb_stream_finalize_write(out, stream.value);

  calloc.free(bufferC);
  libgit2.git_odb_stream_free(stream.value);
  calloc.free(stream);

  return out;
}

/// Close an open object database.
void free(Pointer<git_odb> db) => libgit2.git_odb_free(db);

/// Close an ODB object.
///
/// This method must always be called once a odb object is no longer needed,
/// otherwise memory will leak.
void freeObject(Pointer<git_odb_object> object) {
  libgit2.git_odb_object_free(object);
}
