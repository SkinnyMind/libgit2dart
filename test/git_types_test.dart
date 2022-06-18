import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/git_types.dart';
import 'package:test/test.dart';

void main() {
  group('GitTypes', () {
    test('ReferenceType returns correct values', () {
      const expected = {
        ReferenceType.invalid: 0,
        ReferenceType.direct: 1,
        ReferenceType.symbolic: 2,
        ReferenceType.all: 3,
      };
      final actual = {for (final e in ReferenceType.values) e: e.value};
      expect(actual, expected);
    });

    test('GitFilemode returns correct values', () {
      const expected = {
        GitFilemode.unreadable: 0,
        GitFilemode.tree: 16384,
        GitFilemode.blob: 33188,
        GitFilemode.blobExecutable: 33261,
        GitFilemode.link: 40960,
        GitFilemode.commit: 57344,
      };
      final actual = {for (final e in GitFilemode.values) e: e.value};
      expect(actual, expected);
    });

    test('GitSort returns correct values', () {
      const expected = {
        GitSort.none: 0,
        GitSort.topological: 1,
        GitSort.time: 2,
        GitSort.reverse: 4,
      };
      final actual = {for (final e in GitSort.values) e: e.value};
      expect(actual, expected);
    });

    test('GitObject returns correct values', () {
      const expected = {
        GitObject.any: -2,
        GitObject.invalid: -1,
        GitObject.commit: 1,
        GitObject.tree: 2,
        GitObject.blob: 3,
        GitObject.tag: 4,
        GitObject.offsetDelta: 6,
        GitObject.refDelta: 7,
      };
      final actual = {for (final e in GitObject.values) e: e.value};
      expect(actual, expected);
    });

    test('GitRevSpec returns correct values', () {
      const expected = {
        GitRevSpec.single: 1,
        GitRevSpec.range: 2,
        GitRevSpec.mergeBase: 4,
      };
      final actual = {for (final e in GitRevSpec.values) e: e.value};
      expect(actual, expected);
    });

    test('GitBranch returns correct values', () {
      const expected = {
        GitBranch.local: 1,
        GitBranch.remote: 2,
        GitBranch.all: 3,
      };
      final actual = {for (final e in GitBranch.values) e: e.value};
      expect(actual, expected);
    });

    test('GitStatus returns correct values', () {
      const expected = {
        GitStatus.current: 0,
        GitStatus.indexNew: 1,
        GitStatus.indexModified: 2,
        GitStatus.indexDeleted: 4,
        GitStatus.indexRenamed: 8,
        GitStatus.indexTypeChange: 16,
        GitStatus.wtNew: 128,
        GitStatus.wtModified: 256,
        GitStatus.wtDeleted: 512,
        GitStatus.wtTypeChange: 1024,
        GitStatus.wtRenamed: 2048,
        GitStatus.wtUnreadable: 4096,
        GitStatus.ignored: 16384,
        GitStatus.conflicted: 32768,
      };
      final actual = {for (final e in GitStatus.values) e: e.value};
      expect(actual, expected);
    });

    test('GitMergeAnalysis returns correct values', () {
      const expected = {
        GitMergeAnalysis.normal: 1,
        GitMergeAnalysis.upToDate: 2,
        GitMergeAnalysis.fastForward: 4,
        GitMergeAnalysis.unborn: 8,
      };
      final actual = {for (final e in GitMergeAnalysis.values) e: e.value};
      expect(actual, expected);
    });

    test('GitMergePreference returns correct values', () {
      const expected = {
        GitMergePreference.none: 0,
        GitMergePreference.noFastForward: 1,
        GitMergePreference.fastForwardOnly: 2,
      };
      final actual = {for (final e in GitMergePreference.values) e: e.value};
      expect(actual, expected);
    });

    test('GitRepositoryState returns correct values', () {
      const expected = {
        GitRepositoryState.none: 0,
        GitRepositoryState.merge: 1,
        GitRepositoryState.revert: 2,
        GitRepositoryState.revertSequence: 3,
        GitRepositoryState.cherrypick: 4,
        GitRepositoryState.cherrypickSequence: 5,
        GitRepositoryState.bisect: 6,
        GitRepositoryState.rebase: 7,
        GitRepositoryState.rebaseInteractive: 8,
        GitRepositoryState.rebaseMerge: 9,
        GitRepositoryState.applyMailbox: 10,
        GitRepositoryState.applyMailboxOrRebase: 11,
      };
      final actual = {for (final e in GitRepositoryState.values) e: e.value};
      expect(actual, expected);
    });

    test('GitMergeFlag returns correct values', () {
      const expected = {
        GitMergeFlag.findRenames: 1,
        GitMergeFlag.failOnConflict: 2,
        GitMergeFlag.skipREUC: 4,
        GitMergeFlag.noRecursive: 8,
      };
      final actual = {for (final e in GitMergeFlag.values) e: e.value};
      expect(actual, expected);
    });

    test('GitMergeFileFavor returns correct values', () {
      const expected = {
        GitMergeFileFavor.normal: 0,
        GitMergeFileFavor.ours: 1,
        GitMergeFileFavor.theirs: 2,
        GitMergeFileFavor.union: 3,
      };
      final actual = {for (final e in GitMergeFileFavor.values) e: e.value};
      expect(actual, expected);
    });

    test('GitMergeFileFlag returns correct values', () {
      const expected = {
        GitMergeFileFlag.defaults: 0,
        GitMergeFileFlag.styleMerge: 1,
        GitMergeFileFlag.styleDiff3: 2,
        GitMergeFileFlag.simplifyAlnum: 4,
        GitMergeFileFlag.ignoreWhitespace: 8,
        GitMergeFileFlag.ignoreWhitespaceChange: 16,
        GitMergeFileFlag.ignoreWhitespaceEOL: 32,
        GitMergeFileFlag.diffPatience: 64,
        GitMergeFileFlag.diffMinimal: 128,
        GitMergeFileFlag.styleZdiff3: 256,
        GitMergeFileFlag.acceptConflicts: 512,
      };
      final actual = {for (final e in GitMergeFileFlag.values) e: e.value};
      expect(actual, expected);
    });

    test('GitCheckout returns correct values', () {
      const expected = {
        GitCheckout.none: 0,
        GitCheckout.safe: 1,
        GitCheckout.force: 2,
        GitCheckout.recreateMissing: 4,
        GitCheckout.allowConflicts: 16,
        GitCheckout.removeUntracked: 32,
        GitCheckout.removeIgnored: 64,
        GitCheckout.updateOnly: 128,
        GitCheckout.dontUpdateIndex: 256,
        GitCheckout.noRefresh: 512,
        GitCheckout.skipUnmerged: 1024,
        GitCheckout.useOurs: 2048,
        GitCheckout.useTheirs: 4096,
        GitCheckout.disablePathspecMatch: 8192,
        GitCheckout.skipLockedDirectories: 262144,
        GitCheckout.dontOverwriteIgnored: 524288,
        GitCheckout.conflictStyleMerge: 1048576,
        GitCheckout.conflictStyleDiff3: 2097152,
        GitCheckout.dontRemoveExisting: 4194304,
        GitCheckout.dontWriteIndex: 8388608,
        GitCheckout.dryRun: 16777216,
        GitCheckout.conflictStyleZdiff3: 33554432,
      };
      final actual = {for (final e in GitCheckout.values) e: e.value};
      expect(actual, expected);
    });

    test('GitReset returns correct values', () {
      const expected = {
        GitReset.soft: 1,
        GitReset.mixed: 2,
        GitReset.hard: 3,
      };
      final actual = {for (final e in GitReset.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDiff returns correct values', () {
      const expected = {
        GitDiff.normal: 0,
        GitDiff.reverse: 1,
        GitDiff.includeIgnored: 2,
        GitDiff.recurseIgnoredDirs: 4,
        GitDiff.includeUntracked: 8,
        GitDiff.recurseUntrackedDirs: 16,
        GitDiff.includeUnmodified: 32,
        GitDiff.includeTypechange: 64,
        GitDiff.includeTypechangeTrees: 128,
        GitDiff.ignoreFilemode: 256,
        GitDiff.ignoreSubmodules: 512,
        GitDiff.ignoreCase: 1024,
        GitDiff.includeCaseChange: 2048,
        GitDiff.disablePathspecMatch: 4096,
        GitDiff.skipBinaryCheck: 8192,
        GitDiff.enableFastUntrackedDirs: 16384,
        GitDiff.updateIndex: 32768,
        GitDiff.includeUnreadable: 65536,
        GitDiff.includeUnreadableAsUntracked: 131072,
        GitDiff.indentHeuristic: 262144,
        GitDiff.forceText: 1048576,
        GitDiff.forceBinary: 2097152,
        GitDiff.ignoreWhitespace: 4194304,
        GitDiff.ignoreWhitespaceChange: 8388608,
        GitDiff.ignoreWhitespaceEOL: 16777216,
        GitDiff.showUntrackedContent: 33554432,
        GitDiff.showUnmodified: 67108864,
        GitDiff.patience: 268435456,
        GitDiff.minimal: 536870912,
        GitDiff.showBinary: 1073741824,
      };
      final actual = {for (final e in GitDiff.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDelta returns correct values', () {
      const expected = {
        GitDelta.unmodified: 0,
        GitDelta.added: 1,
        GitDelta.deleted: 2,
        GitDelta.modified: 3,
        GitDelta.renamed: 4,
        GitDelta.copied: 5,
        GitDelta.ignored: 6,
        GitDelta.untracked: 7,
        GitDelta.typechange: 8,
        GitDelta.unreadable: 9,
        GitDelta.conflicted: 10,
      };
      final actual = {for (final e in GitDelta.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDiffFlag returns correct values', () {
      const expected = {
        GitDiffFlag.binary: 1,
        GitDiffFlag.notBinary: 2,
        GitDiffFlag.validId: 4,
        GitDiffFlag.exists: 8,
      };
      final actual = {for (final e in GitDiffFlag.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDiffStats returns correct values', () {
      const expected = {
        GitDiffStats.none: 0,
        GitDiffStats.full: 1,
        GitDiffStats.short: 2,
        GitDiffStats.number: 4,
        GitDiffStats.includeSummary: 8,
      };
      final actual = {for (final e in GitDiffStats.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDiffFind returns correct values', () {
      const expected = {
        GitDiffFind.byConfig: 0,
        GitDiffFind.renames: 1,
        GitDiffFind.renamesFromRewrites: 2,
        GitDiffFind.copies: 4,
        GitDiffFind.copiesFromUnmodified: 8,
        GitDiffFind.rewrites: 16,
        GitDiffFind.breakRewrites: 32,
        GitDiffFind.andBreakRewrites: 48,
        GitDiffFind.forUntracked: 64,
        GitDiffFind.all: 255,
        GitDiffFind.ignoreWhitespace: 4096,
        GitDiffFind.dontIgnoreWhitespace: 8192,
        GitDiffFind.exactMatchOnly: 16384,
        GitDiffFind.breakRewritesForRenamesOnly: 32768,
        GitDiffFind.removeUnmodified: 65536,
      };
      final actual = {for (final e in GitDiffFind.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDiffLine returns correct values', () {
      const expected = {
        GitDiffLine.context: 32,
        GitDiffLine.addition: 43,
        GitDiffLine.deletion: 45,
        GitDiffLine.contextEOFNL: 61,
        GitDiffLine.addEOFNL: 62,
        GitDiffLine.delEOFNL: 60,
        GitDiffLine.fileHeader: 70,
        GitDiffLine.hunkHeader: 72,
        GitDiffLine.binary: 66,
      };
      final actual = {for (final e in GitDiffLine.values) e: e.value};
      expect(actual, expected);
    });

    group('GitApplyLocation', () {
      test('returns correct values', () {
        const expected = [0, 1, 2];
        final actual = GitApplyLocation.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitApplyLocation.workdir.toString(), 'GitApplyLocation.workdir');
      });
    });

    test('GitConfigLevel returns correct values', () {
      const expected = {
        GitConfigLevel.programData: 1,
        GitConfigLevel.system: 2,
        GitConfigLevel.xdg: 3,
        GitConfigLevel.global: 4,
        GitConfigLevel.local: 5,
        GitConfigLevel.app: 6,
        GitConfigLevel.highest: -1,
      };
      final actual = {for (final e in GitConfigLevel.values) e: e.value};
      expect(actual, expected);
    });

    test('GitStash returns correct values', () {
      const expected = {
        GitStash.defaults: 0,
        GitStash.keepIndex: 1,
        GitStash.includeUntracked: 2,
        GitStash.includeIgnored: 4,
      };
      final actual = {for (final e in GitStash.values) e: e.value};
      expect(actual, expected);
    });

    test('GitStashApply returns correct values', () {
      const expected = {
        GitStashApply.defaults: 0,
        GitStashApply.reinstateIndex: 1,
      };
      final actual = {for (final e in GitStashApply.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDirection returns correct values', () {
      const expected = {
        GitDirection.fetch: 0,
        GitDirection.push: 1,
      };
      final actual = {for (final e in GitDirection.values) e: e.value};
      expect(actual, expected);
    });

    test('GitFetchPrune returns correct values', () {
      const expected = {
        GitFetchPrune.unspecified: 0,
        GitFetchPrune.prune: 1,
        GitFetchPrune.noPrune: 2,
      };
      final actual = {for (final e in GitFetchPrune.values) e: e.value};
      expect(actual, expected);
    });

    test('GitRepositoryInit returns correct values', () {
      const expected = {
        GitRepositoryInit.bare: 1,
        GitRepositoryInit.noReinit: 2,
        GitRepositoryInit.noDotGitDir: 4,
        GitRepositoryInit.mkdir: 8,
        GitRepositoryInit.mkpath: 16,
        GitRepositoryInit.externalTemplate: 32,
        GitRepositoryInit.relativeGitlink: 64,
      };
      final actual = {for (final e in GitRepositoryInit.values) e: e.value};
      expect(actual, expected);
    });

    test('GitCredential returns correct values', () {
      const expected = {
        GitCredential.userPassPlainText: 1,
        GitCredential.sshKey: 2,
        GitCredential.sshCustom: 4,
        GitCredential.defaultAuth: 8,
        GitCredential.sshInteractive: 16,
        GitCredential.username: 32,
        GitCredential.sshMemory: 64,
      };
      final actual = {for (final e in GitCredential.values) e: e.value};
      expect(actual, expected);
    });

    test('GitFeature returns correct values', () {
      const expected = {
        GitFeature.threads: 1,
        GitFeature.https: 2,
        GitFeature.ssh: 4,
        GitFeature.nsec: 8,
      };
      final actual = {for (final e in GitFeature.values) e: e.value};
      expect(actual, expected);
    });

    test('GitAttributeCheck returns correct values', () {
      const expected = {
        GitAttributeCheck.fileThenIndex: 0,
        GitAttributeCheck.indexThenFile: 1,
        GitAttributeCheck.indexOnly: 2,
        GitAttributeCheck.noSystem: 4,
        GitAttributeCheck.includeHead: 8,
        GitAttributeCheck.includeCommit: 16,
      };
      final actual = {for (final e in GitAttributeCheck.values) e: e.value};
      expect(actual, expected);
    });

    test('GitBlameFlag returns correct values', () {
      const expected = {
        GitBlameFlag.normal: 0,
        GitBlameFlag.trackCopiesSameFile: 1,
        GitBlameFlag.trackCopiesSameCommitMoves: 2,
        GitBlameFlag.trackCopiesSameCommitCopies: 4,
        GitBlameFlag.trackCopiesAnyCommitCopies: 8,
        GitBlameFlag.firstParent: 16,
        GitBlameFlag.useMailmap: 32,
        GitBlameFlag.ignoreWhitespace: 64,
      };
      final actual = {for (final e in GitBlameFlag.values) e: e.value};
      expect(actual, expected);
    });

    test('GitRebaseOperation returns correct values', () {
      const expected = {
        GitRebaseOperation.pick: 0,
        GitRebaseOperation.reword: 1,
        GitRebaseOperation.edit: 2,
        GitRebaseOperation.squash: 3,
        GitRebaseOperation.fixup: 4,
        GitRebaseOperation.exec: 5,
      };
      final actual = {for (final e in GitRebaseOperation.values) e: e.value};
      expect(actual, expected);
    });

    test('GitDescribeStrategy returns correct values', () {
      const expected = {
        GitDescribeStrategy.defaultStrategy: 0,
        GitDescribeStrategy.tags: 1,
        GitDescribeStrategy.all: 2,
      };
      final actual = {for (final e in GitDescribeStrategy.values) e: e.value};
      expect(actual, expected);
    });

    test('GitSubmoduleIgnore returns correct values', () {
      const expected = {
        GitSubmoduleIgnore.unspecified: -1,
        GitSubmoduleIgnore.none: 1,
        GitSubmoduleIgnore.untracked: 2,
        GitSubmoduleIgnore.dirty: 3,
        GitSubmoduleIgnore.all: 4,
      };
      final actual = {for (final e in GitSubmoduleIgnore.values) e: e.value};
      expect(actual, expected);
    });

    test('GitSubmoduleUpdate returns correct values', () {
      const expected = {
        GitSubmoduleUpdate.checkout: 1,
        GitSubmoduleUpdate.rebase: 2,
        GitSubmoduleUpdate.merge: 3,
        GitSubmoduleUpdate.none: 4,
      };
      final actual = {for (final e in GitSubmoduleUpdate.values) e: e.value};
      expect(actual, expected);
    });

    test('GitSubmoduleStatus returns correct values', () {
      const expected = {
        GitSubmoduleStatus.inHead: 1,
        GitSubmoduleStatus.inIndex: 2,
        GitSubmoduleStatus.inConfig: 4,
        GitSubmoduleStatus.inWorkdir: 8,
        GitSubmoduleStatus.indexAdded: 16,
        GitSubmoduleStatus.indexDeleted: 32,
        GitSubmoduleStatus.indexModified: 64,
        GitSubmoduleStatus.workdirUninitialized: 128,
        GitSubmoduleStatus.workdirAdded: 256,
        GitSubmoduleStatus.workdirDeleted: 512,
        GitSubmoduleStatus.workdirModified: 1024,
        GitSubmoduleStatus.workdirIndexModified: 2048,
        GitSubmoduleStatus.smWorkdirModified: 4096,
        GitSubmoduleStatus.workdirUntracked: 8192,
      };
      final actual = {for (final e in GitSubmoduleStatus.values) e: e.value};
      expect(actual, expected);
    });

    test('GitIndexCapability returns correct values', () {
      const expected = {
        GitIndexCapability.ignoreCase: 1,
        GitIndexCapability.noFileMode: 2,
        GitIndexCapability.noSymlinks: 4,
        GitIndexCapability.fromOwner: -1,
      };
      final actual = {for (final e in GitIndexCapability.values) e: e.value};
      expect(actual, expected);
    });

    test('GitBlobFilter returns correct values', () {
      const expected = {
        GitBlobFilter.checkForBinary: 1,
        GitBlobFilter.noSystemAttributes: 2,
        GitBlobFilter.attributesFromHead: 4,
        GitBlobFilter.attributesFromCommit: 8,
      };
      final actual = {for (final e in GitBlobFilter.values) e: e.value};
      expect(actual, expected);
    });
  });

  test('GitIndexAddOption returns correct values', () {
    const expected = {
      GitIndexAddOption.defaults: 0,
      GitIndexAddOption.force: 1,
      GitIndexAddOption.disablePathspecMatch: 2,
      GitIndexAddOption.checkPathspec: 4,
    };
    final actual = {for (final e in GitIndexAddOption.values) e: e.value};
    expect(actual, expected);
  });

  test('GitWorktree returns correct values', () {
    const expected = {
      GitWorktree.pruneValid: 1,
      GitWorktree.pruneLocked: 2,
      GitWorktree.pruneWorkingTree: 4,
    };
    final actual = {for (final e in GitWorktree.values) e: e.value};
    expect(actual, expected);
  });
}
