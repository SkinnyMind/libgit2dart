/// Valid modes for index and tree entries.
abstract class GitFilemode {
  static const int unreadable = 0;
  static const int tree = 16384;
  static const int blob = 33188;
  static const int blobExecutable = 33261;
  static const int link = 40960;
  static const int commit = 57344;
}
