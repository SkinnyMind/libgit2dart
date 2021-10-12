import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'oid.dart' as oid_bindings;
import '../error.dart';
import '../oid.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Create a new object database with no backends.
///
/// Before the ODB can be used for read/writing, a custom database backend must be
/// manually added.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb> create() {
  final out = calloc<Pointer<git_odb>>();
  final error = libgit2.git_odb_new(out);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Add an on-disk alternate to an existing Object DB.
///
/// Note that the added path must point to an `objects`, not to a full repository,
/// to use it as an alternate store.
///
/// Alternate backends are always checked for objects after all the main backends
/// have been exhausted.
///
/// Writing is disabled on alternate backends.
///
/// Throws a [LibGit2Error] if error occured.
void addDiskAlternate({
  required Pointer<git_odb> odbPointer,
  required String path,
}) {
  final pathC = path.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_odb_add_disk_alternate(odbPointer, pathC);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Determine if an object can be found in the object database by an abbreviated object ID.
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
  return libgit2.git_odb_exists(odbPointer, oidPointer) == 1 ? true : false;
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
  final _oid = oid_bindings.copy(oid);
  _objects.add(Oid(_oid));
  return 0;
}

/// List all objects available in the database.
///
/// Throws a [LibGit2Error] if error occured.
List<Oid> objects(Pointer<git_odb> odb) {
  const except = -1;
  final cb =
      Pointer.fromFunction<Int32 Function(Pointer<git_oid>, Pointer<Void>)>(
          _forEachCb, except);
  final error = libgit2.git_odb_foreach(odb, cb, nullptr);

  if (error < 0) {
    _objects.clear();
    throw LibGit2Error(libgit2.git_error_last());
  }

  final result = _objects.toList(growable: false);
  _objects.clear();

  return result;
}

/// Read an object from the database.
///
/// This method queries all available ODB backends trying to read the given OID.
///
/// The returned object is reference counted and internally cached, so it should be
/// closed by the user once it's no longer in use.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb_object> read({
  required Pointer<git_odb> odbPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_odb_object>>();
  final error = libgit2.git_odb_read(out, odbPointer, oidPointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
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
/// This is the uncompressed, raw data as read from the ODB, without the leading header.
String objectData(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_data(object).cast<Utf8>().toDartString();
}

/// Return the size of an ODB object.
///
/// This is the real size of the `data` buffer, not the actual size of the object.
int objectSize(Pointer<git_odb_object> object) {
  return libgit2.git_odb_object_size(object);
}

/// Close an ODB object.
///
/// This method must always be called once a odb object is no longer needed,
/// otherwise memory will leak.
void objectFree(Pointer<git_odb_object> object) {
  libgit2.git_odb_object_free(object);
}

/// Write raw data to into the object database.
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

  final buffer = data.toNativeUtf8().cast<Int8>();
  final writeError = libgit2.git_odb_stream_write(
    stream.value,
    buffer,
    data.length,
  );

  if (writeError < 0) {
    calloc.free(buffer);
    libgit2.git_odb_stream_free(stream.value);
    throw LibGit2Error(libgit2.git_error_last());
  }

  final out = calloc<git_oid>();
  final finalizeError = libgit2.git_odb_stream_finalize_write(
    out,
    stream.value,
  );

  calloc.free(buffer);
  libgit2.git_odb_stream_free(stream.value);

  if (finalizeError < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Get the number of ODB backend objects.
int backendsCount(Pointer<git_odb> odb) => libgit2.git_odb_num_backends(odb);

/// Lookup an ODB backend object by index.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb_backend> getBackend({
  required Pointer<git_odb> odbPointer,
  required int position,
}) {
  final out = calloc<Pointer<git_odb_backend>>();
  final error = libgit2.git_odb_get_backend(out, odbPointer, position);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Close an open object database.
void free(Pointer<git_odb> db) => libgit2.git_odb_free(db);
