import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/config.dart' as config;
import 'util.dart';

/// [Config] provides management of global configuration options
/// (system, global, XDG, excluding repository config)
class Config {
  /// Initializes a new instance of [Config] class.
  ///
  /// If [path] isn't provided, opens global, XDG and system config files.
  ///
  /// [path] should point to single on-disk file; it's expected to be a native
  /// Git config file following the default Git config syntax (see man git-config).
  ///
  /// [Config] object should be closed with [close] function to release allocated memory.
  Config({this.path}) {
    libgit2.git_libgit2_init();

    if (path == null) {
      configPointer = config.openDefault();
    } else {
      configPointer = config.open(path!);
    }

    libgit2.git_libgit2_shutdown();
  }

  /// Path to on-disk config file provided by user.
  String? path;

  /// Pointer to memory address for allocated config object.
  late Pointer<Pointer<git_config>> configPointer;

  /// Get boolean value of `key` [variable]
  bool getBool(String variable) {
    return config.getBool(configPointer.value, variable);
  }

  ///Get integer value of `key` [variable]
  int getInt(String variable) {
    return config.getInt(configPointer.value, variable);
  }

  ///Get string value of `key` [variable]
  String getString(String variable) {
    return config.getString(configPointer.value, variable);
  }

  /// Set value of config key
  // TODO

  /// Releases memory allocated for config object.
  void close() {
    calloc.free(configPointer);
  }
}
