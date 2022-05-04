import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as path;

import '../test/helpers/util.dart';

// These examples are basic emulation of core Git CLI functions demonstrating
// basic libgit2dart API usage. Be advised that they don't have error handling,
// copy with caution.

void main() {
  // Prepare empty directory for repository.
  final tmpDir = Directory.systemTemp.createTempSync('example_repo');

  // Initialize a repository.
  final repo = initRepo(tmpDir.path);

  // Setup user name and email.
  setupNameAndEmail(repo);

  // Stage untracked file.
  const fileName = 'file.txt';
  final filePath = path.join(repo.workdir, fileName);
  File(filePath).createSync();
  stageUntracked(repo: repo, filePath: fileName);

  // Stage modified file.
  File(filePath).writeAsStringSync('some edit\n');
  stageModified(repo: repo, filePath: fileName);

  // Check repository status.
  repoStatus(repo);

  // Commit changes.
  commitChanges(repo);

  // View commit history.
  viewHistory(repo);

  // View a particular commit.
  viewCommit(repo);

  // View changes before commiting.
  File(filePath).writeAsStringSync('some changes\n');
  viewChanges(repo);

  // Discard staged changes.
  stageModified(repo: repo, filePath: fileName);
  discardStaged(repo: repo, filePath: fileName);

  // Discard changes in the working directory.
  discardNotStaged(repo: repo, filePath: fileName);

  // Remove tracked file from the index and current working tree.
  removeFile(repo: repo, filePath: fileName);

  // Amend the most recent commit.
  amendCommit(repo);

  // Create and switch to a new local branch.
  createAndSwitchToBranch(repo);

  // List all branches.
  listBranches(repo);

  // Merge two branches.
  mergeBranches(repo);

  // Delete a branch.
  deleteBranch(repo);

  // Add a remote repository.
  addRemote(repo);

  // View remote URLs.
  viewRemoteUrls(repo);

  // Remove a remote repository.
  removeRemote(repo);

  // Pull changes from a remote repository.
  pullChanges(repo);

  // Push changes to a remote repository.
  pushChanges(repo);

  // Push a new branch to remote repository.
  pushNewBranch(repo);

  // Clean up.
  tmpDir.deleteSync(recursive: true);
}

/// Initialize a repository at provided path.
///
/// Similar to `git init`.
Repository initRepo(String path) {
  final repo = Repository.init(path: path);
  stdout.writeln('Initialized empty Git repository in ${repo.path}');
  return repo;
}

/// Setup user name and email.
///
/// Similar to:
/// - `git config --add user.name "User Name"`
/// - `git config --add user.email "user@email.com"`
void setupNameAndEmail(Repository repo) {
  final config = repo.config;
  config['user.name'] = 'User Name';
  config['user.email'] = 'user@email.com';
  stdout.writeln('\nSetup user name and email:');
  stdout.writeln('user.name=${config['user.name'].value}');
  stdout.writeln('user.email=${config['user.email'].value}');
}

/// Stage untracked file.
///
/// Similar to `git add file.txt`
void stageUntracked({required Repository repo, required String filePath}) {
  final index = repo.index;
  index.add(filePath);
  index.write();
  stdout.writeln('\nStaged previously untracked file $filePath');
}

/// Stage modified file.
///
/// Similar to `git add file.txt`
void stageModified({required Repository repo, required String filePath}) {
  final index = repo.index;
  index.updateAll([filePath]);
  index.write();
  stdout.writeln('\nChanges to $filePath were staged');
}

/// Check repository status.
///
/// Similar to `git status`
void repoStatus(Repository repo) {
  stdout.writeln('\nChanges to be committed:');
  for (final file in repo.status.entries) {
    if (file.value.contains(GitStatus.indexNew)) {
      stdout.writeln('\tnew file: \t${file.key}');
    }
    if (file.value.contains(GitStatus.indexModified)) {
      stdout.writeln('\tmodified: \t${file.key}');
    }
  }
}

/// Commit changes.
///
/// Similar to `git commit -m "initial commit"`
void commitChanges(Repository repo) {
  final signature = repo.defaultSignature;
  const commitMessage = 'initial commit\n';

  repo.index.write();

  final oid = Commit.create(
    repo: repo,
    updateRef: 'HEAD',
    author: signature,
    committer: signature,
    message: commitMessage,
    tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
    parents: [], // root commit doesn't have parents
  );

  stdout.writeln(
    '\n[${repo.head.shorthand} (root-commit) ${oid.sha.substring(0, 7)}] '
    '$commitMessage',
  );
}

/// View commit history.
///
/// Similar to `git log`
void viewHistory(Repository repo) {
  final commits = repo.log(oid: repo.head.target);

  for (final commit in commits) {
    stdout.writeln('\ncommit ${commit.oid.sha}');
    stdout.writeln('Author: ${commit.author.name} <${commit.author.email}>');
    stdout.writeln(
      'Date:   ${DateTime.fromMillisecondsSinceEpoch(commit.time * 1000)} '
      '${commit.timeOffset}',
    );
    stdout.writeln('\n\t${commit.message}');
  }
}

/// View a particular commit.
///
/// Similar to `git show aaf8f1e`
void viewCommit(Repository repo) {
  final commit = Commit.lookup(repo: repo, oid: repo.head.target);

  stdout.writeln('\ncommit ${commit.oid.sha}');
  stdout.writeln('Author: ${commit.author.name} <${commit.author.email}>');
  stdout.writeln(
    'Date:   ${DateTime.fromMillisecondsSinceEpoch(commit.time * 1000)} '
    '${commit.timeOffset}',
  );
  stdout.writeln('\n\t${commit.message}');

  final diff = Diff.treeToTree(
    repo: repo,
    oldTree: null,
    newTree: commit.tree,
  );
  stdout.writeln('\n${diff.patch}');
}

/// View changes before commiting.
///
/// Similar to `git diff`
void viewChanges(Repository repo) {
  final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
  stdout.writeln('\n${diff.patch}');
}

/// Discard staged changes.
///
/// Similar to `git restore --staged file.txt`
void discardStaged({required Repository repo, required String filePath}) {
  repo.resetDefault(oid: repo.head.target, pathspec: [filePath]);
  stdout.writeln('Staged changes to $filePath were discarded');
}

/// Discard changes in the working directory.
///
/// Similar to `git restore file.txt`
void discardNotStaged({required Repository repo, required String filePath}) {
  final patch = Patch.fromBuffers(
    // Current content of modified file.
    oldBuffer: File(path.join(repo.workdir, filePath)).readAsStringSync(),
    oldBufferPath: filePath,
    // Old content of file as found in previously written blob.
    newBuffer: Blob.lookup(repo: repo, oid: repo.index[filePath].oid).content,
    newBufferPath: filePath,
  );

  // Apply a diff to the repository, making changes in working directory.
  Diff.parse(patch.text).apply(repo: repo);
  stdout.writeln('\nChanges to $filePath in working directory were discarded.');
}

/// Remove tracked files from the index and current working tree.
///
/// Similar to `git rm file.txt`
void removeFile({required Repository repo, required String filePath}) {
  File(path.join(repo.workdir, filePath)).deleteSync();
  repo.index.updateAll([filePath]);
  stdout.writeln('\nrm $filePath');
}

/// Amend the most recent commit.
///
/// Similar to `git commit --amend -m "Updated message for the previous commit"`
void amendCommit(Repository repo) {
  const commitMessage = "Updated message for the previous commit\n";

  repo.index.write();

  final oid = Commit.amend(
    repo: repo,
    commit: Commit.lookup(repo: repo, oid: repo.head.target),
    updateRef: 'HEAD',
    message: commitMessage,
    tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
  );

  stdout.writeln(
    '\n[${repo.head.shorthand} ${oid.sha.substring(0, 7)}] '
    '$commitMessage',
  );
}

/// Create and switch to a new local branch.
///
/// Similar to `git checkout -b new-branch`
void createAndSwitchToBranch(Repository repo) {
  final branch = Branch.create(
    repo: repo,
    name: 'new-branch',
    target: Commit.lookup(repo: repo, oid: repo.head.target),
  );
  final fullName = 'refs/heads/${branch.name}';
  Checkout.reference(repo: repo, name: fullName);
  repo.setHead(fullName);
  stdout.writeln('Switched to a new branch "${repo.head.name}"');
}

/// List all branches.
///
/// Similar to `git branch -a`
void listBranches(Repository repo) {
  stdout.writeln();

  final branches = repo.branches;
  for (final branch in branches) {
    stdout.writeln(
      repo.head.shorthand == branch.name
          ? '* ${branch.name}'
          : '  ${branch.name}',
    );
  }
}

/// Merge two branches.
///
/// Example shows the simplest fast-forward merge. In reality you could find
/// the base between commits with [Merge.base], perform analysis for merge with
/// [Merge.analysis] and based on result invoke further needed methods.
///
/// Similar to `git merge new-branch`
void mergeBranches(Repository repo) {
  // Making changes on 'new-branch'
  File(path.join(repo.workdir, 'new_branch_file.txt')).createSync();

  // Committing on 'new-branch'
  final signature = repo.defaultSignature;
  repo.index.write();
  final newBranchOid = Commit.create(
    repo: repo,
    updateRef: 'HEAD',
    author: signature,
    committer: signature,
    message: 'commit on new-branch\n',
    tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
    parents: [Commit.lookup(repo: repo, oid: repo.head.target)],
  );

  // Switching to 'master'
  Checkout.reference(repo: repo, name: 'refs/heads/master');
  repo.setHead('refs/heads/master');

  // Merging commit into HEAD and writing results into the working directory.
  // Repository is put into a merging state.
  Merge.commit(
    repo: repo,
    commit: AnnotatedCommit.lookup(repo: repo, oid: newBranchOid),
  );

  // Staging merged files.
  repo.index.addAll(repo.status.keys.toList());

  // Committing on 'master'
  repo.index.write();
  final parent = Commit.lookup(repo: repo, oid: repo.head.target);
  final masterOid = Commit.create(
    repo: repo,
    updateRef: 'HEAD',
    author: signature,
    committer: signature,
    message: 'commit on new-branch\n',
    tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
    parents: [parent],
  );

  // Clearing up merging state of repository after commit is done
  repo.stateCleanup();

  stdout.writeln(
    '\nUpdating ${parent.oid.sha.substring(0, 7)}..'
    '${masterOid.sha.substring(0, 7)}',
  );
}

/// Delete a branch.
///
/// Similar to `git branch -d new-branch`
void deleteBranch(Repository repo) {
  const name = 'new-branch';
  final tip = Branch.lookup(repo: repo, name: name).target.sha;
  Branch.delete(repo: repo, name: name);
  stdout.writeln('\nDeleted branch $name (was ${tip.substring(0, 7)}).');
}

/// Add a remote repository.
///
/// Similar to `git remote add origin https://some.url`
void addRemote(Repository repo) {
  const remoteName = 'origin';
  const url = 'https://some.url';
  Remote.create(repo: repo, name: remoteName, url: url);
}

/// View remote URLs.
///
/// Similar to `git remote -v`
void viewRemoteUrls(Repository repo) {
  for (final remoteName in repo.remotes) {
    final remote = Remote.lookup(repo: repo, name: remoteName);
    stdout.writeln('\n${remote.name}  ${remote.url} (fetch)');
    stdout.writeln('${remote.name}  ${remote.url} (push)');
  }
}

/// Remove a remote repository.
///
/// Similar to `git remote remove origin`
void removeRemote(Repository repo) {
  Remote.delete(repo: repo, name: 'origin');
}

/// Pull changes from a remote repository.
///
/// Similar to `git pull`
void pullChanges(Repository repo) {
  // Prepare "origin" repository to pull from
  final originDir = setupRepo(
    Directory(path.join('test', 'assets', 'test_repo')),
  );

  // Add remote
  const remoteName = 'origin';
  final remote = Remote.create(
    repo: repo,
    name: remoteName,
    url: originDir.path,
  );

  // Fetch changes
  remote.fetch();

  // Merge changes
  final theirHead = Reference.lookup(
    repo: repo,
    name: 'refs/remotes/origin/master',
  ).target;
  final analysis = Merge.analysis(repo: repo, theirHead: theirHead);

  // In reality there should be more checks for analysis result (if we should
  // perform merge, or checkout if fast-forward is available, etc.)
  if (analysis.result.contains(GitMergeAnalysis.normal)) {
    final commit = AnnotatedCommit.lookup(repo: repo, oid: theirHead);
    Merge.commit(repo: repo, commit: commit);
  }

  // Make merge commit
  repo.index.write();
  Commit.create(
    repo: repo,
    updateRef: 'HEAD',
    author: repo.defaultSignature,
    committer: repo.defaultSignature,
    message: 'Merge branch "master" of some remote\n',
    tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
    parents: [
      Commit.lookup(repo: repo, oid: repo.head.target),
      Commit.lookup(repo: repo, oid: theirHead),
    ],
  );
  repo.stateCleanup();

  // Remove "origin" repository
  originDir.deleteSync(recursive: true);
}

/// Push changes to a remote repository.
///
/// Similar to `git push bare master`
void pushChanges(Repository repo) {
  // Prepare bare repository to push to
  final bareDir = setupRepo(
    Directory(path.join('test', 'assets', 'empty_bare.git')),
  );

  // Add remote
  const remoteName = 'bare';
  final url = bareDir.path;
  Remote.create(repo: repo, name: remoteName, url: url);
  Remote.addPush(repo: repo, remote: remoteName, refspec: 'refs/heads/master');

  // Push changes
  final remote = Remote.lookup(repo: repo, name: remoteName);
  remote.push();

  // Remove bare repository
  bareDir.deleteSync(recursive: true);
}

/// Push a new branch to remote repository.
///
/// Similar to `git push -u another-origin new-branch`
void pushNewBranch(Repository repo) {
  // Prepare bare repository to push to
  final bareDir = setupRepo(
    Directory(path.join('test', 'assets', 'empty_bare.git')),
  );

  // Create new branch
  final branch = Branch.create(
    repo: repo,
    name: 'new-branch',
    target: Commit.lookup(repo: repo, oid: repo.head.target),
  );

  // Add remote
  const remoteName = 'another-origin';
  final url = bareDir.path;
  Remote.create(repo: repo, name: remoteName, url: url);
  Remote.addPush(
    repo: repo,
    remote: remoteName,
    refspec: 'refs/heads/new-branch',
  );

  // Set upstream for the branch
  final trackingRef = Reference.create(
    repo: repo,
    name: 'refs/remotes/bare/new-branch',
    target: 'refs/heads/new-branch',
  );
  branch.setUpstream(trackingRef.shorthand);

  // Push new branch
  final remote = Remote.lookup(repo: repo, name: remoteName);
  remote.push();

  // Remove bare repository
  bareDir.deleteSync(recursive: true);
}
