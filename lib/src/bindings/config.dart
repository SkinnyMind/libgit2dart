// coverage:ignore-file

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Create a new config instance containing a single on-disk file. The returned
/// config must be freed with [free].
Pointer<git_config> open(String path) {
  final out = calloc<Pointer<git_config>>();
  final pathC = path.toChar();
  libgit2.git_config_open_ondisk(out, pathC);

  calloc.free(pathC);

  return out.value;
}

/// Open the global, XDG and system configuration files.
///
/// Utility wrapper that finds the global, XDG and system configuration
/// files and opens them into a single prioritized config object that can
/// be used when accessing default config data outside a repository.
///
/// The returned config must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> openDefault() {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_config_open_default(out);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Locate the path to the global configuration file.
///
/// The user or global configuration file is usually located in
/// `$HOME/.gitconfig`.
///
/// This method will try to guess the full path to that file, if the file
/// exists. The returned path may be used to load the global configuration file.
///
/// This method will not guess the path to the xdg compatible config file
/// (`.config/git/config`).
///
/// Throws a [LibGit2Error] if error occured.
String findGlobal() {
  final out = calloc<git_buf>();
  final error = libgit2.git_config_find_global(out);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Locate the path to the system configuration file.
///
/// If `/etc/gitconfig` doesn't exist, it will look for
/// `%PROGRAMFILES%\Git\etc\gitconfig`
///
/// Throws a [LibGit2Error] if error occured.
String findSystem() {
  final out = calloc<git_buf>();
  final error = libgit2.git_config_find_system(out);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Locate the path to the global xdg compatible configuration file.
///
/// The xdg compatible configuration file is usually located in
/// `$HOME/.config/git/config`.
///
/// This method will try to guess the full path to that file, if the file
/// exists. The returned path may be used to load the xdg compatible
/// configuration file.
///
/// Throws a [LibGit2Error] if error occured.
String findXdg() {
  final out = calloc<git_buf>();
  final error = libgit2.git_config_find_xdg(out);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a snapshot of the configuration. The returned config must be freed
/// with [free].
///
/// Create a snapshot of the current state of a configuration, which allows you
/// to look into a consistent view of the configuration for looking up complex
/// values (e.g. a remote, submodule).
Pointer<git_config> snapshot(Pointer<git_config> config) {
  final out = calloc<Pointer<git_config>>();
  libgit2.git_config_snapshot(out, config);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Get the config entry of a config variable. The returned config entry must
/// be freed with [freeEntry].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config_entry> getEntry({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  final out = calloc<Pointer<git_config_entry>>();
  final nameC = variable.toChar();
  final error = libgit2.git_config_get_entry(out, configPointer, nameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Set the value of a boolean config variable in the config file with the
/// highest level (usually the local one).
void setBool({
  required Pointer<git_config> configPointer,
  required String variable,
  required bool value,
}) {
  final nameC = variable.toChar();
  final valueC = value ? 1 : 0;
  libgit2.git_config_set_bool(configPointer, nameC, valueC);
  calloc.free(nameC);
}

/// Set the value of an integer config variable in the config file with the
/// highest level (usually the local one).
void setInt({
  required Pointer<git_config> configPointer,
  required String variable,
  required int value,
}) {
  final nameC = variable.toChar();
  libgit2.git_config_set_int64(configPointer, nameC, value);
  calloc.free(nameC);
}

/// Set the value of a string config variable in the config file with the
/// highest level (usually the local one).
void setString({
  required Pointer<git_config> configPointer,
  required String variable,
  required String value,
}) {
  final nameC = variable.toChar();
  final valueC = value.toChar();
  libgit2.git_config_set_string(configPointer, nameC, valueC);
  calloc.free(nameC);
  calloc.free(valueC);
}

/// Iterate over all the config variables. The returned iterator must be freed
/// with [freeIterator].
Pointer<git_config_iterator> iterator(Pointer<git_config> cfg) {
  final out = calloc<Pointer<git_config_iterator>>();
  libgit2.git_config_iterator_new(out, cfg);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Delete a config variable from the config file with the highest level
/// (usually the local one).
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_config> configPointer,
  required String variable,
}) {
  final nameC = variable.toChar();
  final error = libgit2.git_config_delete_entry(configPointer, nameC);

  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Iterate over the values of a multivar.
///
/// If [regexp] is present, then the iterator will only iterate over all
/// values which match the pattern.
///
/// The regular expression is applied case-sensitively on the normalized form
/// of the variable name: the section and variable parts are lower-cased. The
/// subsection is left unchanged.
List<String> multivarValues({
  required Pointer<git_config> configPointer,
  required String variable,
  String? regexp,
}) {
  final nameC = variable.toChar();
  final regexpC = regexp?.toChar() ?? nullptr;
  final iterator = calloc<Pointer<git_config_iterator>>();
  final entry = calloc<Pointer<git_config_entry>>();

  libgit2.git_config_multivar_iterator_new(
    iterator,
    configPointer,
    nameC,
    regexpC,
  );

  var error = 0;
  final entries = <String>[];

  while (error == 0) {
    error = libgit2.git_config_next(entry, iterator.value);
    if (error != -31) {
      entries.add(entry.value.ref.value.toDartString());
    } else {
      break;
    }
  }

  calloc.free(nameC);
  calloc.free(regexpC);
  libgit2.git_config_iterator_free(iterator.value);
  calloc.free(iterator);
  calloc.free(entry);

  return entries;
}

/// Set the value of a multivar config variable in the config file with the
/// highest level (usually the local one).
///
/// The [regexp] is applied case-sensitively on the value.
void setMultivar({
  required Pointer<git_config> configPointer,
  required String variable,
  required String regexp,
  required String value,
}) {
  final nameC = variable.toChar();
  final regexpC = regexp.toChar();
  final valueC = value.toChar();

  libgit2.git_config_set_multivar(configPointer, nameC, regexpC, valueC);

  calloc.free(nameC);
  calloc.free(regexpC);
  calloc.free(valueC);
}

/// Deletes one or several values from a multivar in the config file
/// with the highest level (usually the local one).
///
/// The [regexp] is applied case-sensitively on the value.
void deleteMultivar({
  required Pointer<git_config> configPointer,
  required String variable,
  required String regexp,
}) {
  final nameC = variable.toChar();
  final regexpC = regexp.toChar();

  libgit2.git_config_delete_multivar(configPointer, nameC, regexpC);

  calloc.free(nameC);
  calloc.free(regexpC);
}

/// Free the configuration and its associated memory and files.
void free(Pointer<git_config> cfg) => libgit2.git_config_free(cfg);

/// Free a config entry.
void freeEntry(Pointer<git_config_entry> entry) =>
    libgit2.git_config_entry_free(entry);

/// Free a config iterator.
void freeIterator(Pointer<git_config_iterator> iter) =>
    libgit2.git_config_iterator_free(iter);
