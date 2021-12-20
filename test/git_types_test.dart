import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/git_types.dart';
import 'package:test/test.dart';

void main() {
  group('GitTypes', () {
    group('ReferenceType', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 3];
        final actual = ReferenceType.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(ReferenceType.invalid.toString(), 'ReferenceType.invalid');
      });
    });

    group('GitFilemode', () {
      test('returns correct values', () {
        const expected = [0, 16384, 33188, 33261, 40960, 57344];
        final actual = GitFilemode.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitFilemode.unreadable.toString(), 'GitFilemode.unreadable');
      });
    });

    group('GitSort', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4];
        final actual = GitSort.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitSort.none.toString(), 'GitSort.none');
      });
    });

    group('GitObject', () {
      test('returns correct values', () {
        const expected = [-2, -1, 1, 2, 3, 4, 6, 7];
        final actual = GitObject.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitObject.any.toString(), 'GitObject.any');
      });
    });

    group('GitRevSpec', () {
      test('returns correct values', () {
        const expected = [1, 2, 4];
        final actual = GitRevSpec.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitRevSpec.single.toString(), 'GitRevSpec.single');
      });
    });

    group('GitBranch', () {
      test('returns correct values', () {
        const expected = [1, 2, 3];
        final actual = GitBranch.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitBranch.local.toString(), 'GitBranch.local');
      });
    });

    group('GitStatus', () {
      test('returns correct values', () {
        const expected = [
          0,
          1,
          2,
          4,
          8,
          16,
          128,
          256,
          512,
          1024,
          2048,
          4096,
          16384,
          32768,
        ];
        final actual = GitStatus.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitStatus.current.toString(), 'GitStatus.current');
      });
    });

    group('GitMergeAnalysis', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8];
        final actual = GitMergeAnalysis.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitMergeAnalysis.none.toString(), 'GitMergeAnalysis.none');
      });
    });

    group('GitMergePreference', () {
      test('returns correct values', () {
        const expected = [0, 1, 2];
        final actual = GitMergePreference.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitMergePreference.none.toString(), 'GitMergePreference.none');
      });
    });

    group('GitRepositoryState', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        final actual = GitRepositoryState.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitRepositoryState.none.toString(), 'GitRepositoryState.none');
      });
    });

    group('GitMergeFlag', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8];
        final actual = GitMergeFlag.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitMergeFlag.findRenames.toString(), 'GitMergeFlag.findRenames');
      });
    });

    group('GitMergeFileFavor', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 3];
        final actual = GitMergeFileFavor.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitMergeFileFavor.normal.toString(), 'GitMergeFileFavor.normal');
      });
    });

    group('GitMergeFileFlag', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4, 8, 16, 32, 64, 128];
        final actual = GitMergeFileFlag.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitMergeFileFlag.defaults.toString(),
          'GitMergeFileFlag.defaults',
        );
      });
    });

    group('GitCheckout', () {
      test('returns correct values', () {
        const expected = [
          0,
          1,
          2,
          4,
          16,
          32,
          64,
          128,
          256,
          512,
          1024,
          2048,
          4096,
          8192,
          262144,
          524288,
          1048576,
          2097152,
          4194304,
          8388608,
          16777216,
        ];
        final actual = GitCheckout.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitCheckout.none.toString(), 'GitCheckout.none');
      });
    });

    group('GitReset', () {
      test('returns correct values', () {
        const expected = [1, 2, 3];
        final actual = GitReset.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitReset.soft.toString(), 'GitReset.soft');
      });
    });

    group('GitDiff', () {
      test('returns correct values', () {
        const expected = [
          0,
          1,
          2,
          4,
          8,
          16,
          32,
          64,
          128,
          256,
          512,
          1024,
          2048,
          4096,
          8192,
          16384,
          32768,
          65536,
          131072,
          262144,
          1048576,
          2097152,
          4194304,
          8388608,
          16777216,
          33554432,
          67108864,
          268435456,
          536870912,
          1073741824,
        ];
        final actual = GitDiff.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDiff.normal.toString(), 'GitDiff.normal');
      });
    });

    group('GitDelta', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        final actual = GitDelta.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDelta.unmodified.toString(), 'GitDelta.unmodified');
      });
    });

    group('GitDiffFlag', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8];
        final actual = GitDiffFlag.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDiffFlag.binary.toString(), 'GitDiffFlag.binary');
      });
    });

    group('GitDiffStats', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4, 8];
        final actual = GitDiffStats.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDiffStats.none.toString(), 'GitDiffStats.none');
      });
    });

    group('GitDiffFind', () {
      test('returns correct values', () {
        const expected = [
          0,
          1,
          2,
          4,
          8,
          16,
          32,
          48,
          64,
          255,
          4096,
          8192,
          16384,
          32768,
          65536,
        ];
        final actual = GitDiffFind.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDiffFind.byConfig.toString(), 'GitDiffFind.byConfig');
      });
    });

    group('GitDiffLine', () {
      test('returns correct values', () {
        const expected = [32, 43, 45, 61, 62, 60, 70, 72, 66];
        final actual = GitDiffLine.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDiffLine.context.toString(), 'GitDiffLine.context');
      });
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

    group('GitConfigLevel', () {
      test('returns correct values', () {
        const expected = [1, 2, 3, 4, 5, 6, -1];
        final actual = GitConfigLevel.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitConfigLevel.programData.toString(),
          'GitConfigLevel.programData',
        );
      });
    });

    group('GitStash', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4];
        final actual = GitStash.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitStash.defaults.toString(), 'GitStash.defaults');
      });
    });

    group('GitStashApply', () {
      test('returns correct values', () {
        const expected = [0, 1];
        final actual = GitStashApply.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitStashApply.defaults.toString(), 'GitStashApply.defaults');
      });
    });

    group('GitDirection', () {
      test('returns correct values', () {
        const expected = [0, 1];
        final actual = GitDirection.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDirection.fetch.toString(), 'GitDirection.fetch');
      });
    });

    group('GitFetchPrune', () {
      test('returns correct values', () {
        const expected = [0, 1, 2];
        final actual = GitFetchPrune.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitFetchPrune.unspecified.toString(),
          'GitFetchPrune.unspecified',
        );
      });
    });

    group('GitRepositoryInit', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8, 16, 32, 64];
        final actual = GitRepositoryInit.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitRepositoryInit.bare.toString(), 'GitRepositoryInit.bare');
      });
    });

    group('GitCredential', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8, 16, 32, 64];
        final actual = GitCredential.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitCredential.sshKey.toString(), 'GitCredential.sshKey');
      });
    });

    group('GitFeature', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8];
        final actual = GitFeature.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitFeature.threads.toString(), 'GitFeature.threads');
      });
    });

    group('GitAttributeCheck', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4, 8, 16];
        final actual = GitAttributeCheck.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitAttributeCheck.fileThenIndex.toString(),
          'GitAttributeCheck.fileThenIndex',
        );
      });
    });

    group('GitBlameFlag', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 4, 8, 16, 32, 64];
        final actual = GitBlameFlag.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitBlameFlag.normal.toString(), 'GitBlameFlag.normal');
      });
    });

    group('GitRebaseOperation', () {
      test('returns correct values', () {
        const expected = [0, 1, 2, 3, 4, 5];
        final actual = GitRebaseOperation.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitRebaseOperation.pick.toString(), 'GitRebaseOperation.pick');
      });
    });

    group('GitDescribeStrategy', () {
      test('returns correct values', () {
        const expected = [0, 1, 2];
        final actual = GitDescribeStrategy.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitDescribeStrategy.tags.toString(), 'GitDescribeStrategy.tags');
      });
    });

    group('GitSubmoduleIgnore', () {
      test('returns correct values', () {
        const expected = [-1, 1, 2, 3, 4];
        final actual = GitSubmoduleIgnore.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitSubmoduleIgnore.none.toString(), 'GitSubmoduleIgnore.none');
      });
    });

    group('GitSubmoduleUpdate', () {
      test('returns correct values', () {
        const expected = [1, 2, 3, 4];
        final actual = GitSubmoduleUpdate.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(GitSubmoduleUpdate.none.toString(), 'GitSubmoduleUpdate.none');
      });
    });

    group('GitSubmoduleStatus', () {
      test('returns correct values', () {
        const expected = [
          1,
          2,
          4,
          8,
          16,
          32,
          64,
          128,
          256,
          512,
          1024,
          2048,
          4096,
          8192,
        ];
        final actual = GitSubmoduleStatus.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitSubmoduleStatus.inHead.toString(),
          'GitSubmoduleStatus.inHead',
        );
      });
    });

    group('GitIndexCapability', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, -1];
        final actual = GitIndexCapability.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitIndexCapability.ignoreCase.toString(),
          'GitIndexCapability.ignoreCase',
        );
      });
    });

    group('GitBlobFilter', () {
      test('returns correct values', () {
        const expected = [1, 2, 4, 8];
        final actual = GitBlobFilter.values.map((e) => e.value).toList();
        expect(actual, expected);
      });

      test('returns string representation of object', () {
        expect(
          GitBlobFilter.checkForBinary.toString(),
          'GitBlobFilter.checkForBinary',
        );
      });
    });
  });
}
