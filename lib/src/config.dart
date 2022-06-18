import 'dart:collection';
import 'dart:ffi';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/config.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

class Config with IterableMixin<ConfigEntry> {
  /// Initializes a new instance of [Config] class from provided
  /// pointer to config object in memory.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Config.open]
  /// - [Config.system]
  /// - [Config.global]
  /// - [Config.xdg]
  @internal
  Config(this._configPointer) {
    _finalizer.attach(this, _configPointer, detach: this);
  }

  /// Opens config file at provided [path].
  ///
  /// If [path] isn't provided, opens global, XDG and system config files.
  ///
  /// [path] should point to single on-disk file; it's expected to be a native
  /// Git config file following the default Git config syntax (see
  /// `man git-config`).
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

    _finalizer.attach(this, _configPointer, detach: this);
  }

  /// Opens the system configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.system() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findSystem());
    // coverage:ignore-start
    _finalizer.attach(this, _configPointer, detach: this);
    // coverage:ignore-end
  }

  /// Opens the global configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.global() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findGlobal());
    // coverage:ignore-start
    _finalizer.attach(this, _configPointer, detach: this);
    // coverage:ignore-end
  }

  /// Opens the global XDG configuration file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config.xdg() {
    libgit2.git_libgit2_init();

    _configPointer = bindings.open(bindings.findXdg());
    // coverage:ignore-start
    _finalizer.attach(this, _configPointer, detach: this);
    // coverage:ignore-end
  }

  /// Pointer to memory address for allocated config object.
  late final Pointer<git_config> _configPointer;

  /// The snapshot of the current state of a configuration, which allows you to
  /// look into a consistent view of the configuration for looking up complex
  /// values (e.g. a remote, submodule).
  Config get snapshot => Config(bindings.snapshot(_configPointer));

  /// Returns the [ConfigEntry] of a [variable].
  ConfigEntry operator [](String variable) {
    final entryPointer = bindings.getEntry(
      configPointer: _configPointer,
      variable: variable,
    );
    final name = entryPointer.ref.name.toDartString();
    final value = entryPointer.ref.value.toDartString();
    final includeDepth = entryPointer.ref.include_depth;
    final level = GitConfigLevel.values.firstWhere(
      (e) => entryPointer.ref.level == e.value,
    );

    bindings.freeEntry(entryPointer);

    return ConfigEntry._(
      name: name,
      value: value,
      includeDepth: includeDepth,
      level: level,
    );
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
  ///
  /// The regular expression is applied case-sensitively on the normalized form
  /// of the variable name: the section and variable parts are lower-cased. The
  /// subsection is left unchanged.
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

  /// Deletes one or several values from a multivar [variable] in the config
  /// file with the highest level (usually the local one).
  ///
  /// The [regexp] is applied case-sensitively on the value.
  void deleteMultivar({required String variable, required String regexp}) {
    bindings.deleteMultivar(
      configPointer: _configPointer,
      variable: variable,
      regexp: regexp,
    );
  }

  /// Releases memory allocated for config object.
  void free() {
    bindings.free(_configPointer);
    _finalizer.detach(this);
  }

  @override
  Iterator<ConfigEntry> get iterator =>
      _ConfigIterator(bindings.iterator(_configPointer));
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_config>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

@immutable
class ConfigEntry extends Equatable {
  const ConfigEntry._({
    required this.name,
    required this.value,
    required this.includeDepth,
    required this.level,
  });

  /// Name of the entry (normalised).
  final String name;

  /// Value of the entry.
  final String value;

  /// Depth of includes where this variable was found
  final int includeDepth;

  /// Which config file this was found in.
  final GitConfigLevel level;

  @override
  String toString() {
    return 'ConfigEntry{name: $name, value: $value, '
        'includeDepth: $includeDepth, level: $level}';
  }

  @override
  List<Object?> get props => [name, value, includeDepth, level];
}

class _ConfigIterator implements Iterator<ConfigEntry> {
  _ConfigIterator(this._iteratorPointer) {
    _iteratorFinalizer.attach(this, _iteratorPointer);
  }

  /// Pointer to memory address for allocated config iterator.
  final Pointer<git_config_iterator> _iteratorPointer;

  late ConfigEntry _currentEntry;
  int error = 0;
  final entry = calloc<Pointer<git_config_entry>>();

  @override
  ConfigEntry get current => _currentEntry;

  @override
  bool moveNext() {
    if (error < 0) {
      return false;
    } else {
      error = libgit2.git_config_next(entry, _iteratorPointer);
      if (error != -31) {
        final name = entry.value.ref.name.toDartString();
        final value = entry.value.ref.value.toDartString();
        final includeDepth = entry.value.ref.include_depth;
        final level = GitConfigLevel.values.firstWhere(
          (e) => entry.value.ref.level == e.value,
        );

        _currentEntry = ConfigEntry._(
          name: name,
          value: value,
          includeDepth: includeDepth,
          level: level,
        );

        return true;
      } else {
        return false;
      }
    }
  }
}

// coverage:ignore-start
final _iteratorFinalizer = Finalizer<Pointer<git_config_iterator>>(
  (pointer) => bindings.freeIterator(pointer),
);
// coverage:ignore-end
