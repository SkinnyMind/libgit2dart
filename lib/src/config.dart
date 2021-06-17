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

    variables = config.getVariables(configPointer.value);

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
      variables = config.getVariables(configPointer.value);
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
      variables = config.getVariables(configPointer.value);
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
      variables = config.getVariables(configPointer.value);
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

  /// Map of key/value entries from config file.
  Map<String, dynamic> variables = {};

  /// Sets value of config key
  void setVariable(String key, dynamic value) {
    try {
      if (value.runtimeType == bool) {
        config.setBool(configPointer.value, key, value);
      } else if (value.runtimeType == int) {
        config.setInt(configPointer.value, key, value);
      } else {
        config.setString(configPointer.value, key, value);
      }
      variables = config.getVariables(configPointer.value);
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
      variables = config.getVariables(configPointer.value);
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

  /// Releases memory allocated for config object.
  void close() {
    calloc.free(configPointer);
  }
}
