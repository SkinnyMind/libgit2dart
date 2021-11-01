import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart' show Ansi, Logger;
import 'package:libgit2dart/src/util.dart';
import 'package:path/path.dart' as path;
import 'package:pub_cache/pub_cache.dart';

/// Checks whether libgit2 library is present in directory for [platform].
bool libgit2IsPresent(String platform) {
  final result = File.fromUri(
    Directory.current.uri.resolve(path.join(libDir, platform, getLibName())),
  ).existsSync();
  return result;
}

/// Copies prebuilt libgit2 library from package in '.pub_cache' into correct
/// directory for [platform].
Future<void> copyLibrary(String platform) async {
  final logger = Logger.standard();
  final ansi = Ansi(Ansi.terminalSupportsAnsi);

  if (libgit2IsPresent(platform)) {
    if (libgit2Version == getVersionNumber()) {
      logger.stdout('${ansi.green}libgit2 for $platform is already available.');
    } else {
      logger.stdout(
        '${ansi.red}libgit2 for $platform is outdated.\n'
        'Please run following commands: \n'
        'dart run libgit2dart:setup clean\n'
        'dart run libgit2dart:setup\n\n',
      );
    }
  } else {
    final pubCache = PubCache();
    final pubCacheDir =
        pubCache.getLatestVersion('libgit2dart')!.resolve()!.location;
    final libName = getLibName();
    final libUri = pubCacheDir.uri.resolve(path.join(platform, libName));

    logger.stdout('Copying libgit2 for $platform');
    final destination = path.join(libDir, platform);
    Directory(destination).createSync(recursive: true);
    File.fromUri(libUri).copySync(path.join(destination, libName));

    logger.stdout(
      '${ansi.green}Done! libgit2 for $platform is now available!'
      '${ansi.none}',
    );
  }
}

class CleanCommand extends Command<void> {
  @override
  String get description => 'Cleans copied libgit2 libraries.';

  @override
  String get name => 'clean';

  @override
  void run() {
    final logger = Logger.standard();
    logger.stdout('Cleaning...');
    Directory(libDir).deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  final runner = CommandRunner<void>(
    'setup',
    'Setups the libgit2 library.',
  );
  runner.addCommand(CleanCommand());

  (args.isEmpty) ? copyLibrary(Platform.operatingSystem) : runner.run(args);
}
