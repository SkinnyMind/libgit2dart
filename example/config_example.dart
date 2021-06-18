import 'package:libgit2dart/libgit2dart.dart';

void main() {
  // Open system + global config file.
  final config = Config.open();

  print('All entries of system/global config:');
  final entries = config.getEntries();
  for (final entry in entries.entries) {
    print('${entry.key}: ${entry.value}');
  }
  // .close should be called on object to free memory when done.
  config.close();

  // Open config file at provided path.
  // Exception is thrown if file not found.
  try {
    final repoConfig = Config.open(path: '.git/config');

    print('All entries of repo config:');
    final entries = repoConfig.getEntries();
    for (final entry in entries.entries) {
      print('${entry.key}: ${entry.value}');
    }

    repoConfig.close();
  } catch (e) {
    print(e);
  }

  // Open global config file if there's one.
  // Exception is thrown if file not found.
  try {
    final globalConfig = Config.global();

    // get value of config variable
    final userName = globalConfig.getValue('user.name');
    print('\nUser Name from global config: $userName');

    globalConfig.close();
  } catch (e) {
    print('\n$e');
  }
}
