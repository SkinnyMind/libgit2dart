import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/config.dart' as bindings;
import 'util.dart';

class Config with IterableMixin<ConfigEntry> {
  /// Initializes a new instance of [Config] class from provided
  /// pointer to config object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Config(this._configPointer);

  /// Opens config file at provided [path].
  ///
  /// If [path] isn't provided, opens global, XDG and system config files.
  ///
  /// [path] should point to single on-disk file; it's expected to be a native
  /// Git config file following the default Git config syntax (see man git-config).
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws an [Exception] if file not found at provided path.
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

  /// Opens the system configuration file.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.system() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findSystem());
  }

  /// Opens the global configuration file.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.global() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findGlobal());
  }

  /// Opens the global XDG configuration file.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.xdg() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findXdg());
  }

  /// Pointer to memory address for allocated config object.
  late final Pointer<git_config> _configPointer;

  /// The snapshot of the current state of a configuration, which allows you to look
  /// into a consistent view of the configuration for looking up complex values
  /// (e.g. a remote, submodule).
  Config get snapshot => Config(bindings.snapshot(_configPointer));

  /// Returns the [ConfigEntry] of a [variable].
  ConfigEntry operator [](String variable) {
    return ConfigEntry(bindings.getEntry(
      configPointer: _configPointer,
      variable: variable,
    ));
  }

  /// Sets the [value] of config [variable].
  ///
  /// Throws [ArgumentError] if provided [value] is not bool, int or String.
  void operator []=(String variable, Object value) {
    if (value is bool) {
      bindings.setBool(
        configPointer: _configPointer,
        variable: variable,
        value: value,
      );
    } else if (value is int) {
      bindings.setInt(
        configPointer: _configPointer,
        variable: variable,
        value: value,
      );
    } else if (value is String) {
      bindings.setString(
        configPointer: _configPointer,
        variable: variable,
        value: value,
      );
    } else {
      throw ArgumentError.value('$value must be either bool, int or String');
    }
  }

  /// Deletes [variable] from the config file with the highest level
  /// (usually the local one).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void delete(String variable) =>
      bindings.delete(configPointer: _configPointer, variable: variable);

  /// Returns list of values for multivar [variable]
  ///
  /// If [regexp] is present, then the iterator will only iterate over all
  /// values which match the pattern.
  List<String> multivar({required String variable, String? regexp}) {
    return bindings.multivarValues(
      configPointer: _configPointer,
      variable: variable,
      regexp: regexp,
    );
  }

  /// Sets the [value] of a multivar [variable] in the config file with the
  /// highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] sets [value] for all values of a multivar [variable].
  void setMultivar({
    required String variable,
    required String regexp,
    required String value,
  }) {
    bindings.setMultivar(
      configPointer: _configPointer,
      variable: variable,
      regexp: regexp,
      value: value,
    );
  }

  /// Deletes one or several values from a multivar [variable] in the config file
  /// with the highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  /// Empty [regexp] deletes all values of a multivar [variable].
  void deleteMultivar({required String variable, required String regexp}) {
    bindings.deleteMultivar(
      configPointer: _configPointer,
      variable: variable,
      regexp: regexp,
    );
  }

  /// Releases memory allocated for config object.
  void free() => bindings.free(_configPointer);

  @override
  Iterator<ConfigEntry> get iterator =>
      _ConfigIterator(bindings.iterator(_configPointer));
}

class ConfigEntry {
  /// Initializes a new instance of [ConfigEntry] class from provided
  /// pointer to config entry object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  const ConfigEntry(this._configEntryPointer);

  /// Pointer to memory address for allocated config entry object.
  final Pointer<git_config_entry> _configEntryPointer;

  /// Name of the entry (normalised).
  String get name => _configEntryPointer.ref.name.cast<Utf8>().toDartString();

  /// Value of the entry.
  String get value => _configEntryPointer.ref.value.cast<Utf8>().toDartString();

  /// Depth of includes where this variable was found
  int get includeDepth => _configEntryPointer.ref.include_depth;

  /// Which config file this was found in.
  GitConfigLevel get level {
    return GitConfigLevel.values.singleWhere(
      (e) => _configEntryPointer.ref.level == e.value,
    );
  }

  /// Releases memory allocated for config entry object.
  void free() => calloc.free(_configEntryPointer);

  @override
  String toString() {
    return 'ConfigEntry{name: $name, value: $value, includeDepth: $includeDepth, level: $level}';
  }
}

class _ConfigIterator implements Iterator<ConfigEntry> {
  _ConfigIterator(this._iteratorPointer);

  /// Pointer to memory address for allocated config iterator.
  final Pointer<git_config_iterator> _iteratorPointer;

  ConfigEntry? _currentEntry;
  int error = 0;
  final entry = calloc<Pointer<git_config_entry>>();

  @override
  ConfigEntry get current => _currentEntry!;

  @override
  bool moveNext() {
    if (error < 0) {
      return false;
    } else {
      error = libgit2.git_config_next(entry, _iteratorPointer);
      if (error != -31) {
        _currentEntry = ConfigEntry(entry.value);
        return true;
      } else {
        return false;
      }
    }
  }
}
