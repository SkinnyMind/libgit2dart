/// Basic type of any Git reference.
class ReferenceType {
  const ReferenceType._(this._value);
  final int _value;

  /// Invalid reference.
  static const invalid = ReferenceType._(0);

  /// A reference that points at an object id.
  static const direct = ReferenceType._(1);

  /// A reference that points at another reference.
  static const symbolic = ReferenceType._(2);

  static const all = ReferenceType._(3);

  int get value => _value;
}

/// Valid modes for index and tree entries.
class GitFilemode {
  const GitFilemode._(this._value);
  final int _value;

  static const unreadable = GitFilemode._(0);

  static const tree = GitFilemode._(16384);

  static const blob = GitFilemode._(33188);

  static const blobExecutable = GitFilemode._(33261);

  static const link = GitFilemode._(40960);

  static const commit = GitFilemode._(57344);

  int get value => _value;
}

/// Flags to specify the sorting which a revwalk should perform.
class GitSort {
  const GitSort._(this._value);
  final int _value;

  /// Sort the output with the same default method from `git`: reverse
  /// chronological order. This is the default sorting for new walkers.
  static const none = GitSort._(0);

  /// Sort the repository contents in topological order (no parents before
  /// all of its children are shown); this sorting mode can be combined
  /// with time sorting to produce `git`'s `--date-order``.
  static const topological = GitSort._(1);

  /// Sort the repository contents by commit time;
  /// this sorting mode can be combined with topological sorting.
  static const time = GitSort._(2);

  /// Iterate through the repository contents in reverse order; this sorting mode
  /// can be combined with any of the above.
  static const reverse = GitSort._(4);

  int get value => _value;
}

/// Basic type (loose or packed) of any Git object.
class GitObject {
  const GitObject._(this._value);
  final int _value;

  /// Object can be any of the following.
  static const any = GitObject._(-2);

  /// Object is invalid.
  static const invalid = GitObject._(-1);

  /// A commit object.
  static const commit = GitObject._(1);

  /// A tree (directory listing) object.
  static const tree = GitObject._(2);

  /// A file revision object.
  static const blob = GitObject._(3);

  /// An annotated tag object.
  static const tag = GitObject._(4);

  /// A delta, base is given by an offset.
  static const offsetDelta = GitObject._(6);

  /// A delta, base is given by object id.
  static const refDelta = GitObject._(7);

  int get value => _value;
}

/// Revparse flags, indicate the intended behavior of the spec.
class GitRevParse {
  const GitRevParse._(this._value);
  final int _value;

  /// The spec targeted a single object.
  static const single = GitRevParse._(1);

  /// The spec targeted a range of commits.
  static const range = GitRevParse._(2);

  /// The spec used the '...' operator, which invokes special semantics.
  static const mergeBase = GitRevParse._(4);

  int get value => _value;
}

/// Basic type of any Git branch.
class GitBranch {
  const GitBranch._(this._value);
  final int _value;

  static const local = GitBranch._(1);

  static const remote = GitBranch._(2);

  static const all = GitBranch._(3);

  int get value => _value;
}
