import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';

import 'helpers.dart';

void main() async {
  // Preparing example repository.
  final tmpDir = '${Directory.systemTemp.path}/example_repo/';
  await prepareRepo(tmpDir);

  // Open system + global config file.
  final config = Config.open();

  print('All entries of system/global config:');
  final entries = config.getEntries();
  for (final entry in entries.entries) {
    print('${entry.key}: ${entry.value}');
  }
  // free() should be called on object to free memory when done.
  config.free();

  // Open config file at provided path.
  // Exception is thrown if file not found.
  try {
    final repoConfig = Config.open('$tmpDir/.git/config');

    print('\nAll entries of repo config:');
    final entries = repoConfig.getEntries();
    for (final entry in entries.entries) {
      print('${entry.key}: ${entry.value}');
    }

    // Set value of config variable
    repoConfig.setValue('core.variable', 'value');
    print(
        '\nNew value for variable "core.variable": ${repoConfig.getValue('core.variable')}');

    // Delete variable
    repoConfig.deleteEntry('core.variable');

    repoConfig.free();
  } catch (e) {
    print(e);
  }

  // Open global config file if there's one.
  // Exception is thrown if file not found.
  try {
    final globalConfig = Config.global();

    // Get value of config variable.
    final userName = globalConfig.getValue('user.name');
    print('\nUser Name from global config: $userName');

    globalConfig.free();
  } catch (e) {
    print('\n$e');
  }

  // Removing example repository.
  await disposeRepo(tmpDir);
}
