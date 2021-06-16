import 'package:libgit2dart/libgit2dart.dart';

void main() {
  // Open system + global config file.
  final config = Config.open();

  print('All entries of system/global config:');
  // config.variables hold key/value from config file
  for (final entry in config.variables.entries) {
    print('${entry.key}: ${entry.value}');
  }
  // .close should be called on object to free memory when done.
  config.close();

  // Open config file at provided path.
  // Exception is thrown if file not found.
  try {
    final repoConfig = Config.open(path: '.git/config');

    print('All entries of repo config:');
    for (final entry in repoConfig.variables.entries) {
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

    final userName = globalConfig.variables['user.name'];
    print('\nUser Name from global config: $userName');

    globalConfig.close();
  } catch (e) {
    print('\n$e');
  }
}
