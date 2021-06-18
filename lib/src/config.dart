import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/config.dart' as config;
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
      try {
        configPointer = config.openDefault();
      } catch (e) {
        rethrow;
      }
    } else {
      try {
        if (File(path!).existsSync()) {
          configPointer = config.open(path!);
        } else {
          throw Exception('File not found');
        }
      } catch (e) {
        rethrow;
      }
    }

    libgit2.git_libgit2_shutdown();
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the system configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.system() {
    libgit2.git_libgit2_init();

    try {
      final systemPath = config.findSystem();
      configPointer = config.open(systemPath);
    } catch (e) {
      configPointer = nullptr;
      rethrow;
    }

    libgit2.git_libgit2_shutdown();
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.global() {
    libgit2.git_libgit2_init();

    try {
      final globalPath = config.findGlobal();
      configPointer = config.open(globalPath);
    } catch (e) {
      configPointer = nullptr;
      rethrow;
    }

    libgit2.git_libgit2_shutdown();
  }

  /// Initializes a new instance of [Config] class.
  ///
  /// Opens the global XDG configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.xdg() {
    libgit2.git_libgit2_init();

    try {
      final xdgPath = config.findXdg();
      configPointer = config.open(xdgPath);
    } catch (e) {
      configPointer = nullptr;
      rethrow;
    }

    libgit2.git_libgit2_shutdown();
  }

  /// Path to on-disk config file provided by user.
  String? path;

  /// Pointer to memory address for allocated config object.
  late Pointer<Pointer<git_config>> configPointer;

  /// Returns map of all the config variables and their values
  Map<String, String> getEntries() {
    return config.getEntries(configPointer.value);
  }

  /// Returns the value of config [variable]
  String getValue(String variable) {
    try {
      return config.getValue(configPointer.value, variable);
    } catch (e) {
      rethrow;
    }
  }

  /// Sets the [value] of config [variable]
  void setValue(String variable, dynamic value) {
    try {
      if (value.runtimeType == bool) {
        config.setBool(configPointer.value, variable, value);
      } else if (value.runtimeType == int) {
        config.setInt(configPointer.value, variable, value);
      } else {
        config.setString(configPointer.value, variable, value);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes variable from the config file with the highest level
  /// (usually the local one).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteVariable(String key) {
    try {
      config.deleteVariable(configPointer.value, key);
    } catch (e) {
      rethrow;
    }
  }

  /// Returns list of values for multivar [key]
  ///
  /// If [regexp] is present, then the iterator will only iterate over all
  /// values which match the pattern.
  List<String> getMultivar(String key, {String? regexp}) {
    return config.getMultivar(configPointer.value, key, regexp);
  }

  /// Sets the [value] of a multivar [key] in the config file with the
  /// highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] sets [value] for all values of a multivar [key]
  void setMultivar(String key, String regexp, String value) {
    config.setMultivar(configPointer.value, key, regexp, value);
  }

  /// Releases memory allocated for config object.
  void close() {
    calloc.free(configPointer);
  }
}
