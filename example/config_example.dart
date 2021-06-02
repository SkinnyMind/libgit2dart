import 'package:libgit2dart/libgit2dart.dart';

void main() {
  final repoConfig = Config(path: '.git/config');

  final isBare = repoConfig.getBool('core.bare');
  final isLoggingAllRefUpdates = repoConfig.getBool('core.logallrefupdates');
  final repoFormatVersion = repoConfig.getInt('core.repositoryformatversion');
  final remoteOriginUrl = repoConfig.getString('remote.origin.url');

  print('Repository is bare = $isBare');
  print('Logging all ref updates = $isLoggingAllRefUpdates');
  print('Repository format version = $repoFormatVersion');
  print('Remote origin url = $remoteOriginUrl');

  repoConfig.close();
}
