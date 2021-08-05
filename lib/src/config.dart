import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/config.dart' as bindings;
import 'util.dart';

/// [Config] provides management of global configuration options
/// (system, global, XDG, excluding repository config)
class Config {
  Config();

  /// Initializes a new instance of [Config] class.
  ///
  /// If [path] isn't provided, opens global, XDG and system config files.
  ///
  /// [path] should point to single on-disk file; it's expected to be a native
  /// Git config file following the default Git config syntax (see man git-config).
  ///
  /// [Config] object should be closed with [close] function to release allocated memory.
  Config.open({this.path}) {
    libgit2.git_libgit2_init();

    if (path == null) {
      _configPointer = bindings.openDefault().value;
    } else {
      if (File(path!).existsSync()) {
        _configPointer = bindings.open(path!).value;
      } else {
        throw Exception('File not found');
      }
    }
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the system configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.system() {
    libgit2.git_libgit2_init();

    try {
      final systemPath = bindings.findSystem();
      _configPointer = bindings.open(systemPath).value;
    } catch (e) {
      _configPointer = nullptr;
      rethrow;
    }
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.global() {
    libgit2.git_libgit2_init();

    try {
      final globalPath = bindings.findGlobal();
      _configPointer = bindings.open(globalPath).value;
    } catch (e) {
      _configPointer = nullptr;
      rethrow;
    }
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global XDG configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.xdg() {
    libgit2.git_libgit2_init();

    try {
      final xdgPath = bindings.findXdg();
      _configPointer = bindings.open(xdgPath).value;
    } catch (e) {
      _configPointer = nullptr;
      rethrow;
    }
  }

  /// Path to on-disk config file provided by user.
  String? path;

  /// Pointer to memory address for allocated config object.
  late final Pointer<git_config> _configPointer;

  /// Returns map of all the config variables and their values.
  Map<String, String> getEntries() {
    return bindings.getEntries(_configPointer);
  }

  /// Returns the value of config [variable].
  String getValue(String variable) {
    return bindings.getValue(_configPointer, variable);
  }

  /// Sets the [value] of config [variable].
  void setValue(String variable, dynamic value) {
    if (value.runtimeType == bool) {
      bindings.setBool(_configPointer, variable, value);
    } else if (value.runtimeType == int) {
      bindings.setInt(_configPointer, variable, value);
    } else {
      bindings.setString(_configPointer, variable, value);
    }
  }

  /// Deletes [variable] from the config file with the highest level
  /// (usually the local one).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteEntry(String variable) {
    bindings.deleteEntry(_configPointer, variable);
  }

  /// Returns list of values for multivar [variable]
  ///
  /// If [regexp] is present, then the iterator will only iterate over all
  /// values which match the pattern.
  List<String> getMultivarValue(String variable, {String? regexp}) {
    return bindings.getMultivarValue(_configPointer, variable, regexp);
  }

  /// Sets the [value] of a multivar [variable] in the config file with the
  /// highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] sets [value] for all values of a multivar [variable].
  void setMultivarValue(String variable, String regexp, String value) {
    bindings.setMultivarValue(_configPointer, variable, regexp, value);
  }

  /// Deletes one or several values from a multivar [variable] in the config file
  /// with the highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] deletes all values of a multivar [variable].
  void deleteMultivar(String variable, String regexp) {
    bindings.deleteMultivar(_configPointer, variable, regexp);
  }

  /// Releases memory allocated for config object.
  void close() {
    calloc.free(_configPointer);
    libgit2.git_libgit2_shutdown();
  }
}
