import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';

import 'bindings/libgit2_bindings.dart';
import 'bindings/refspec.dart' as bindings;
import 'git_types.dart';

class Refspec {
  /// Initializes a new instance of the [Refspec] class
  /// from provided pointer to refspec object in memory.
  Refspec(this._refspecPointer);

  /// Pointer to memory address for allocated refspec object.
  final Pointer<git_refspec> _refspecPointer;

  /// Returns the source specifier.
  String get source => bindings.source(_refspecPointer);

  /// Returns the destination specifier.
  String get destination => bindings.destination(_refspecPointer);

  /// Returns the force update setting.
  bool get force => bindings.force(_refspecPointer);

  /// Returns the refspec's string.
  String get string => bindings.string(_refspecPointer);

  /// Returns the refspec's direction (fetch or push).
  GitDirection get direction {
    return bindings.direction(_refspecPointer) == 0
        ? GitDirection.fetch
        : GitDirection.push;
  }

  /// Checks if a refspec's source descriptor matches a reference.
  bool matchesSource(String refname) =>
      bindings.matchesSource(_refspecPointer, refname);

  /// Checks if a refspec's destination descriptor matches a reference.
  bool matchesDestination(String refname) =>
      bindings.matchesDestination(_refspecPointer, refname);

  /// Transforms a reference to its target following the refspec's rules.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String transform(String name) => bindings.transform(_refspecPointer, name);

  /// Transforms a target reference to its source reference following the refspec's rules.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String rTransform(String name) => bindings.rTransform(_refspecPointer, name);
}
