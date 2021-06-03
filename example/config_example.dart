import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repoConfig = Config(path: '.git/config');

  print('All entries of repo config:');
  for (final entry in repoConfig.entries.entries) {
    print('${entry.key}: ${entry.value}');
  }

  repoConfig.close();

  try {
    final systemConfig = Config.system();

    print(
        '\nUser Name from system config: ${systemConfig.entries['user.name']}');

    systemConfig.close();
  } catch (e) {
    print('\n$e');
  }

  try {
    final globalConfig = Config.global();

    print(
        '\nUser Name from global config: ${globalConfig.entries['user.name']}');

    globalConfig.close();
  } catch (e) {
    print('\n$e');
  }

  try {
    final xdgConfig = Config.xdg();
    print('\nAll entries of repo config:');

    print('\nUser Name from xdg config: ${xdgConfig.entries['user.name']}');

    xdgConfig.close();
  } catch (e) {
    print('\n$e');
  }

  final config = Config();

  print('\nAll entries of system/global config:');
  for (final entry in config.entries.entries) {
    print('${entry.key}: ${entry.value}');
  }
  config.close();
}
