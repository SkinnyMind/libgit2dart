import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart' show Ansi, Logger;
import 'package:libgit2dart/src/util.dart';

bool libgit2IsPresent(String platform) {
  final result = File.fromUri(
    Directory.current.uri
        .resolve('.dart_tool/libgit2/$platform/${getLibName()}'),
  ).existsSync();
  return result;
}

/// Extracts a tar.gz file.
void extract(String fileName, String dir) {
  final tarGzFile = File(fileName).readAsBytesSync();
  final archive = GZipDecoder().decodeBytes(tarGzFile, verify: true);
  final tarData = TarDecoder().decodeBytes(archive, verify: true);
  for (final file in tarData) {
    File('$dir${file.name}')
      ..createSync(recursive: true)
      ..writeAsBytesSync(file.content as List<int>);
  }
}

/// Downloads libgit2 from GitHub releases, extracts and places it in correct
/// directory.
Future<void> download(String platform) async {
  final logger = Logger.standard();
  final ansi = Ansi(Ansi.terminalSupportsAnsi);

  if (libgit2IsPresent(platform)) {
    if (libgit2Version == getVersionNumber()) {
      logger.stdout('${ansi.green}libgit2 for $platform is already available.');
    } else {
      logger.stdout(
        '${ansi.red}libgit2 for $platform is outdated. Run: \n'
        'flutter pub run libgit2dart:setup clean\n'
        'flutter pub run libgit2dart:setup',
      );
    }
  } else {
    final fileName = '$platform.tar.gz';
    final downloadUrl = '$libUrl$fileName';
    logger.stdout('Downloading libgit2 for $platform');
    logger.stdout(downloadUrl);

    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();
      final fileSink = File(fileName).openWrite();
      await response.pipe(fileSink);
      await fileSink.flush();
      await fileSink.close();
      httpClient.close();
    } catch (error) {
      Exception("Can't download. Check your internet connection.");
    }

    logger.stdout('${ansi.yellow}Extracting libgit2 for $platform${ansi.none}');
    Directory('$libDir$platform/').createSync(recursive: true);
    extract(fileName, '$libDir$platform/');
    logger.stdout('${ansi.green}Done! Cleaning up...');

    File(fileName).deleteSync();

    logger.stdout(
      '${ansi.green}Done! libgit2 for $platform is now available!'
      '${ansi.none}',
    );
  }
}

class CleanCommand extends Command<void> {
  @override
  String get description => 'Cleans downloaded libraries.';

  @override
  String get name => 'clean';

  @override
  void run() {
    final logger = Logger.standard();
    logger.stdout('cleaning...');
    Directory(libDir).deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  final runner = CommandRunner<void>(
    'setup',
    'Downloads the libgit2 library.',
  );
  runner.addCommand(CleanCommand());

  (args.isEmpty) ? download(Platform.operatingSystem) : runner.run(args);
}
