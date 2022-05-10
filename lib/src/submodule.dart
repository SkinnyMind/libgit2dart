import 'dart:ffi';
import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/submodule.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Submodule extends Equatable {
  /// Lookups submodule information by [name] or path (they are usually the
  /// same).
  ///
  /// Throws a [LibGit2Error] if error occured.
  Submodule.lookup({required Repository repo, required String name}) {
    _submodulePointer = bindings.lookup(
      repoPointer: repo.pointer,
      name: name,
    );
    _finalizer.attach(this, _submodulePointer, detach: this);
  }

  /// Adds a submodule to the index.
  ///
  /// [url] is the URL for the submodule's remote.
  ///
  /// [path] is the path at which the submodule should be created.
  ///
  /// [useGitLink] determines if workdir should contain a gitlink to the repo in `.git/modules`
  /// vs. repo directly in workdir. Default is true.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Submodule.add({
    required Repository repo,
    required String url,
    required String path,
    bool useGitlink = true,
    Callbacks callbacks = const Callbacks(),
  }) {
    _submodulePointer = bindings.addSetup(
      repoPointer: repo.pointer,
      url: url,
      path: path,
      useGitlink: useGitlink,
    );

    bindings.clone(submodule: _submodulePointer, callbacks: callbacks);

    bindings.addFinalize(_submodulePointer);

    _finalizer.attach(this, _submodulePointer, detach: this);
  }

  /// Pointer to memory address for allocated submodule object.
  late final Pointer<git_submodule> _submodulePointer;

  /// Copies submodule info into ".git/config" file.
  ///
  /// Just like `git submodule init`, this copies information about the
  /// submodule into ".git/config".
  ///
  /// By default, existing entries will not be overwritten, but setting
  /// [overwrite] to true forces them to be updated.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void init({
    required Repository repo,
    required String name,
    bool overwrite = false,
  }) {
    final submodulePointer = bindings.lookup(
      repoPointer: repo.pointer,
      name: name,
    );

    bindings.init(submodulePointer: submodulePointer, overwrite: overwrite);

    bindings.free(submodulePointer);
  }

  /// Updates a submodule. This will clone a missing submodule and checkout the
  /// subrepository to the commit specified in the index of the containing
  /// repository. If the submodule repository doesn't contain the target commit
  /// (e.g. because fetchRecurseSubmodules isn't set), then the submodule is
  /// fetched using the fetch options supplied in [callbacks].
  ///
  /// If the submodule is not initialized, setting [init] to true will
  /// initialize the submodule before updating. Otherwise, this will return an
  /// error if attempting to update an uninitialzed repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void update({
    required Repository repo,
    required String name,
    bool init = false,
    Callbacks callbacks = const Callbacks(),
  }) {
    final submodulePointer = bindings.lookup(
      repoPointer: repo.pointer,
      name: name,
    );

    bindings.update(
      submodulePointer: submodulePointer,
      init: init,
      callbacks: callbacks,
    );

    bindings.free(submodulePointer);
  }

  /// Returns a list with all tracked submodules paths of a repository.
  static List<String> list(Repository repo) => bindings.list(repo.pointer);

  /// Opens the repository for a submodule.
  ///
  /// Multiple calls to this function will return distinct git repository
  /// objects.
  ///
  /// This will only work if the submodule is checked out into the working
  /// directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository open() {
    return Repository(bindings.open(_submodulePointer));
  }

  /// Returns the status for a submodule.
  ///
  /// This looks at a submodule and tries to determine the status. How deeply
  /// it examines the working directory to do this will depend on the
  /// combination of [GitSubmoduleIgnore] values provided to [ignore] .
  Set<GitSubmoduleStatus> status({
    GitSubmoduleIgnore ignore = GitSubmoduleIgnore.unspecified,
  }) {
    final resultInt = bindings.status(
      repoPointer: bindings.owner(_submodulePointer),
      name: name,
      ignore: ignore.value,
    );

    return GitSubmoduleStatus.values
        .where((e) => resultInt & e.value == e.value)
        .toSet();
  }

  /// Copies submodule remote info into submodule repo.
  ///
  /// This copies the information about the submodules URL into the checked out
  /// submodule config, acting like `git submodule sync`. This is useful if you
  /// have altered the URL for the submodule (or it has been altered by a fetch
  /// of upstream changes) and you need to update your local repo.
  void sync() => bindings.sync(_submodulePointer);

  /// Rereads submodule info from config, index, and HEAD.
  ///
  /// Call this to reread cached submodule information for this submodule if
  /// you have reason to believe that it has changed.
  ///
  /// Set [force] to true to reload even if the data doesn't seem out of date.
  void reload({bool force = false}) {
    bindings.reload(submodulePointer: _submodulePointer, force: force);
  }

  /// Name of submodule.
  String get name => bindings.name(_submodulePointer);

  /// Path to the submodule.
  ///
  /// The path is almost always the same as the submodule name, but the two
  /// are actually not required to match.
  String get path => bindings.path(_submodulePointer);

  /// URL for the submodule.
  String get url => bindings.url(_submodulePointer);

  /// Sets the URL for the submodule in the configuration.
  ///
  /// After calling this, you may wish to call [sync] to write the changes to
  /// the checked out submodule repository.
  set url(String url) {
    bindings.setUrl(
      repoPointer: bindings.owner(_submodulePointer),
      name: name,
      url: url,
    );
  }

  /// Branch for the submodule.
  String get branch => bindings.branch(_submodulePointer);

  /// Sets the branch for the submodule in the configuration.
  ///
  /// After calling this, you may wish to call [sync] to write the changes to
  /// the checked out submodule repository.
  set branch(String branch) {
    bindings.setBranch(
      repoPointer: bindings.owner(_submodulePointer),
      name: name,
      branch: branch,
    );
  }

  /// [Oid] for the submodule in the current HEAD tree or null if submodule is
  /// not in the HEAD.
  Oid? get headOid {
    final result = bindings.headId(_submodulePointer);
    return result == null ? null : Oid(result);
  }

  /// [Oid] for the submodule in the index or null if submodule is not in the
  /// index.
  Oid? get indexOid {
    final result = bindings.indexId(_submodulePointer);
    return result == null ? null : Oid(result);
  }

  /// [Oid] for the submodule in the current working directory or null if
  /// submodule is not checked out.
  ///
  /// This returns the [Oid] that corresponds to looking up `HEAD` in the
  /// checked out submodule. If there are pending changes in the index or
  /// anything else, this won't notice that. You should call [status] for a
  /// more complete picture about the state of the working directory.
  Oid? get workdirOid {
    final result = bindings.workdirId(_submodulePointer);
    return result == null ? null : Oid(result);
  }

  /// Ignore rule that will be used for the submodule.
  GitSubmoduleIgnore get ignore {
    final ruleInt = bindings.ignore(_submodulePointer);
    return GitSubmoduleIgnore.values.firstWhere((e) => ruleInt == e.value);
  }

  /// Sets the ignore rule for the submodule in the configuration.
  ///
  /// This does not affect any currently-loaded instances.
  set ignore(GitSubmoduleIgnore ignore) {
    final repo = bindings.owner(_submodulePointer);
    bindings.setIgnore(repoPointer: repo, name: name, ignore: ignore.value);
  }

  /// Update rule that will be used for the submodule.
  ///
  /// This value controls the behavior of the `git submodule update` command.
  GitSubmoduleUpdate get updateRule {
    final ruleInt = bindings.updateRule(_submodulePointer);
    return GitSubmoduleUpdate.values.firstWhere((e) => ruleInt == e.value);
  }

  /// Sets the update rule for the submodule in the configuration.
  ///
  /// This setting won't affect any existing instances.
  set updateRule(GitSubmoduleUpdate rule) {
    bindings.setUpdateRule(
      repoPointer: bindings.owner(_submodulePointer),
      name: name,
      update: rule.value,
    );
  }

  /// Releases memory allocated for submodule object.
  void free() {
    bindings.free(_submodulePointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Submodule{name: $name, path: $path, url: $url, branch: $branch, '
        'headOid: $headOid, indexOid: $indexOid, workdirOid: $workdirOid, '
        'ignore: $ignore, updateRule: $updateRule}';
  }

  @override
  List<Object?> get props => [
        name,
        path,
        url,
        branch,
        headOid,
        indexOid,
        workdirOid,
        ignore,
        updateRule,
      ];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_submodule>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
