import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Allocate a new configuration object
///
/// This object is empty, so you have to add a file to it before you can do
/// anything with it.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> newConfig() {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_config_new(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new config instance containing a single on-disk file
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> open(String path) {
  final out = calloc<Pointer<git_config>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_config_open_ondisk(out, pathC);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Open the global, XDG and system configuration files
///
/// Utility wrapper that finds the global, XDG and system configuration
/// files and opens them into a single prioritized config object that can
/// be used when accessing default config data outside a repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> openDefault() {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_config_open_default(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Locate the path to the global configuration file
///
/// The user or global configuration file is usually located in
/// `$HOME/.gitconfig`.
///
/// This method will try to guess the full path to that file, if the file
/// exists. The returned path may be used on any method call to load
/// the global configuration file.
///
/// This method will not guess the path to the xdg compatible config file
/// (`.config/git/config`).
///
/// Throws an error if file has not been found.
String findGlobal() {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final error = libgit2.git_config_find_global(out);

  if (error != 0) {
    throw Error();
  } else {
    return out.ref.ptr.cast<Utf8>().toDartString();
  }
}

/// Locate the path to the system configuration file
///
/// If /etc/gitconfig doesn't exist, it will look for %PROGRAMFILES%\Git\etc\gitconfig
///
/// Throws a [LibGit2Error] if error occured.
String findSystem() {
  final out = calloc<git_buf>();
  final error = libgit2.git_config_find_system(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.ref.ptr.cast<Utf8>().toDartString();
  }
}

/// Locate the path to the global xdg compatible configuration file
///
/// The xdg compatible configuration file is usually located in
/// `$HOME/.config/git/config`.
///
/// Throws a [LibGit2Error] if error occured.
String findXdg() {
  final out = calloc<git_buf>();
  final error = libgit2.git_config_find_xdg(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.ref.ptr.cast<Utf8>().toDartString();
  }
}

/// Create a snapshot of the configuration.
///
/// Create a snapshot of the current state of a configuration, which allows you to look
/// into a consistent view of the configuration for looking up complex values
/// (e.g. a remote, submodule).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> snapshot(Pointer<git_config> config) {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_config_snapshot(out, config);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the config entry of a config variable.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config_entry> getEntry({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  final out = calloc<Pointer<git_config_entry>>();
  final name = variable.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_config_get_entry(out, configPointer, name);

  calloc.free(name);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Set the value of a boolean config variable in the config file with the
/// highest level (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void setBool({
  required Pointer<git_config> configPointer,
  required String variable,
  required bool value,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final valueC = value ? 1 : 0;
  final error = libgit2.git_config_set_bool(configPointer, name, valueC);

  calloc.free(name);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the value of an integer config variable in the config file with the
/// highest level (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void setInt({
  required Pointer<git_config> configPointer,
  required String variable,
  required int value,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_config_set_int64(configPointer, name, value);

  calloc.free(name);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the value of a string config variable in the config file with the
/// highest level (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void setString({
  required Pointer<git_config> configPointer,
  required String variable,
  required String value,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final valueC = value.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_config_set_string(configPointer, name, valueC);

  calloc.free(name);
  calloc.free(valueC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Iterate over all the config variables.
Pointer<git_config_iterator> iterator(Pointer<git_config> cfg) {
  final out = calloc<Pointer<git_config_iterator>>();
  libgit2.git_config_iterator_new(out, cfg);
  return out.value;
}

/// Delete a config variable from the config file with the highest level
/// (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_config_delete_entry(configPointer, name);

  calloc.free(name);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Iterate over the values of a multivar
///
/// If regexp is present, then the iterator will only iterate over all
/// values which match the pattern.
List<String> multivarValues({
  required Pointer<git_config> configPointer,
  required String variable,
  String? regexp,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final regexpC = regexp?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final iterator = calloc<Pointer<git_config_iterator>>();
  final entry = calloc<Pointer<git_config_entry>>();

  libgit2.git_config_multivar_iterator_new(
    iterator,
    configPointer,
    name,
    regexpC,
  );

  var error = 0;
  final entries = <String>[];

  while (error == 0) {
    error = libgit2.git_config_next(entry, iterator.value);
    if (error != -31) {
      entries.add(entry.value.ref.value.cast<Utf8>().toDartString());
    } else {
      break;
    }
  }

  calloc.free(name);
  calloc.free(regexpC);
  calloc.free(iterator);
  calloc.free(entry);

  return entries;
}

/// Set the value of a multivar config variable in the config file with the
/// highest level (usually the local one).
///
/// The regexp is applied case-sensitively on the value.
void setMultivar({
  required Pointer<git_config> configPointer,
  required String variable,
  required String regexp,
  required String value,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final regexpC = regexp.toNativeUtf8().cast<Int8>();
  final valueC = value.toNativeUtf8().cast<Int8>();

  libgit2.git_config_set_multivar(configPointer, name, regexpC, valueC);

  calloc.free(name);
  calloc.free(regexpC);
  calloc.free(valueC);
}

/// Deletes one or several values from a multivar in the config file
/// with the highest level (usually the local one).
///
/// The regexp is applied case-sensitively on the value.
void deleteMultivar({
  required Pointer<git_config> configPointer,
  required String variable,
  required String regexp,
}) {
  final name = variable.toNativeUtf8().cast<Int8>();
  final regexpC = regexp.toNativeUtf8().cast<Int8>();

  libgit2.git_config_delete_multivar(configPointer, name, regexpC);

  calloc.free(name);
  calloc.free(regexpC);
}

/// Free a config iterator.
void iteratorFree(Pointer<git_config_iterator> iter) =>
    libgit2.git_config_iterator_free(iter);

/// Free a config entry.
void entryFree(Pointer<git_config_entry> entry) =>
    libgit2.git_config_entry_free(entry);

/// Free the configuration and its associated memory and files.
void free(Pointer<git_config> cfg) => libgit2.git_config_free(cfg);
