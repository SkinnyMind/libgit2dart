import 'dart:io';
import 'package:libgit2dart/libgit2dart.dart';
import '../test/helpers/util.dart';

void main() {
  // Preparing example repository.
  final tmpDir = setupRepo(Directory('test/assets/testrepo/'));

  // Open system + global config file.
  final config = Config.open();

  print('All entries of system/global config:');
  for (final entry in config) {
    print('${entry.name}: ${entry.value}');
  }
  // free() should be called on object to free memory when done.
  config.free();

  // Open config file at provided path.
  // Exception is thrown if file not found.
  try {
    final repoConfig = Config.open('${tmpDir.path}/.git/config');

    print('\nAll entries of repo config:');
    for (final entry in repoConfig) {
      print('${entry.name}: ${entry.value}');
    }

    // Set value of config variable
    repoConfig['core.variable'] = 'value';
    print(
        '\nNew value for variable "core.variable": ${repoConfig['core.variable']}');

    // Delete variable
    repoConfig.delete('core.variable');

    repoConfig.free();
  } catch (e) {
    print(e);
  }

  // Open global config file if there's one.
  // Exception is thrown if file not found.
  try {
    final globalConfig = Config.global();

    // Get value of config variable.
    final userName = globalConfig['user.name'];
    print('\nUser Name from global config: $userName');

    globalConfig.free();
  } catch (e) {
    print('\n$e');
  }

  // Removing example repository.
  tmpDir.deleteSync(recursive: true);
}
