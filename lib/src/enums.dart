enum ReferenceType { direct, symbolic }

enum GitFilemode { undreadable, tree, blob, blobExecutable, link, commit }

/// Flags to specify the sorting which a revwalk should perform.
///
/// [none] sort the output with the same default method from `git`: reverse
/// chronological order. This is the default sorting for new walkers.
///
/// [topological] sort the repository contents in topological order (no parents before
/// all of its children are shown); this sorting mode can be combined
/// with time sorting to produce `git`'s `--date-order``.
///
/// [time] sort the repository contents by commit time;
/// this sorting mode can be combined with topological sorting.
///
/// [reverse] Iterate through the repository contents in reverse
/// order; this sorting mode can be combined with any of the above.
enum GitSort { none, topological, time, reverse }
