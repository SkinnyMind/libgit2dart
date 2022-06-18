import 'dart:ffi';
import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/refspec.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Refspec extends Equatable {
  /// Initializes a new instance of the [Refspec] class
  /// from provided pointer to refspec object in memory.
  ///
  /// Note: For internal use.
  @internal
  const Refspec(this._refspecPointer);

  /// Pointer to memory address for allocated refspec object.
  final Pointer<git_refspec> _refspecPointer;

  /// Source specifier.
  String get source => bindings.source(_refspecPointer);

  /// Destination specifier.
  String get destination => bindings.destination(_refspecPointer);

  /// Force update setting.
  bool get force => bindings.force(_refspecPointer);

  /// Refspec's string.
  String get string => bindings.string(_refspecPointer);

  /// Refspec's direction (fetch or push).
  GitDirection get direction {
    return bindings.direction(_refspecPointer) == 0
        ? GitDirection.fetch
        : GitDirection.push;
  }

  /// Whether refspec's source descriptor matches a reference.
  bool matchesSource(String refname) {
    return bindings.matchesSource(
      refspecPointer: _refspecPointer,
      refname: refname,
    );
  }

  /// Whether refspec's destination descriptor matches a reference.
  bool matchesDestination(String refname) {
    return bindings.matchesDestination(
      refspecPointer: _refspecPointer,
      refname: refname,
    );
  }

  /// Transforms a reference to its target following the refspec's rules.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String transform(String name) {
    return bindings.transform(
      refspecPointer: _refspecPointer,
      name: name,
    );
  }

  /// Transforms a target reference to its source reference following the
  /// refspec's rules.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String rTransform(String name) {
    return bindings.rTransform(
      refspecPointer: _refspecPointer,
      name: name,
    );
  }

  @override
  String toString() {
    return 'Refspec{source: $source, destination: $destination, force: $force, '
        'string: $string, direction: $direction}';
  }

  @override
  List<Object?> get props => [source, destination, force, string, direction];
}
