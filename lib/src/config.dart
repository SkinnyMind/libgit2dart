import 'dart:ffi';
import 'dart:io';
import 'bindings/libgit2_bindings.dart';
import 'bindings/config.dart' as bindings;
import 'util.dart';

class Config {
  /// Initializes a new instance of [Config] class from provided
  /// pointer to config object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Config(this._configPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Config] class from provided [path].
  ///
  /// If [path] isn't provided, opens global, XDG and system config files.
  ///
  /// [path] should point to single on-disk file; it's expected to be a native
  /// Git config file following the default Git config syntax (see man git-config).
  ///
  /// Should be freed with `free()` to release allocated memory.
  Config.open([String? path]) {
    libgit2.git_libgit2_init();

    if (path == null) {
      _configPointer = bindings.openDefault();
    } else {
      if (File(path).existsSync()) {
        _configPointer = bindings.open(path);
      } else {
        throw Exception('File not found');
      }
    }
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the system configuration file.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.system() {
    libgit2.git_libgit2_init();

    final systemPath = bindings.findSystem();
    _configPointer = bindings.open(systemPath);
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global configuration file.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws an error if file has not been found.
  Config.global() {
    libgit2.git_libgit2_init();

    final globalPath = bindings.findGlobal();
    _configPointer = bindings.open(globalPath);
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global XDG configuration file.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.xdg() {
    libgit2.git_libgit2_init();

    final xdgPath = bindings.findXdg();
    _configPointer = bindings.open(xdgPath);
  }

  /// Pointer to memory address for allocated config object.
  late final Pointer<git_config> _configPointer;

  /// Create a snapshot of the configuration.
  ///
  /// Create a snapshot of the current state of a configuration, which allows you to look
  /// into a consistent view of the configuration for looking up complex values
  /// (e.g. a remote, submodule).
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config get snapshot => Config(bindings.snapshot(_configPointer));

  /// Returns map of all the config variables and their values.
  Map<String, String> get variables => bindings.getEntries(_configPointer);

  /// Returns the value of config [variable].
  String operator [](String variable) =>
      bindings.getValue(_configPointer, variable);

  /// Sets the [value] of config [variable].
  void operator []=(String variable, dynamic value) {
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
  void delete(String variable) => bindings.delete(_configPointer, variable);

  /// Returns list of values for multivar [variable]
  ///
  /// If [regexp] is present, then the iterator will only iterate over all
  /// values which match the pattern.
  List<String> multivar(String variable, {String? regexp}) {
    return bindings.multivarValues(_configPointer, variable, regexp);
  }

  /// Sets the [value] of a multivar [variable] in the config file with the
  /// highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] sets [value] for all values of a multivar [variable].
  void setMultivar(String variable, String regexp, String value) {
    bindings.setMultivar(_configPointer, variable, regexp, value);
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
  void free() {
    bindings.free(_configPointer);
  }
}
