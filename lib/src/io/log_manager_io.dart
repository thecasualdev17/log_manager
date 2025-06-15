import 'package:log_manager/log_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'file_manager/file_manager.dart';

class LogManagerIO {
  LogManagerIO({
    this.writeToDownloadsDirectory = false,
    this.fileExtension = 'log',
    this.logFormat = LogFormats.plainText,
    this.logGroup = LogGroups.daily,
    this.maxFileSize = 2 * 1024 * 1024, // 2 MB
  }) {
    init();
  }

  final bool writeToDownloadsDirectory;
  final String fileExtension;
  final LogFormats logFormat;
  final LogGroups logGroup;
  final int maxFileSize;
  String? _rootPath;
  FileManager _fileManager = FileManager();

  Future<void> init() async {
    if (writeToDownloadsDirectory) {
      _rootPath = (await getDownloadsDirectory())?.path;
    } else {
      _rootPath = (await getApplicationDocumentsDirectory()).path;
    }

    _fileManager = FileManager();
    _fileManager.initialize(
      logDirectory: '$_rootPath/logs',
      archiveDirectory: '$_rootPath/archive',
      extension: fileExtension,
    );
  }

  Future<void> createLog(
    String logMessage, {
    LogLevel logLevel = LogLevel.INFO,
    StackTrace? stacktrace,
  }) async {
    String baseFileName = getBaseFileName();
    if (await _fileManager.logFileExists(fileName: baseFileName)) {
      final fileSize = await _fileManager.getFileSize(fileName: baseFileName);
      if (fileSize >= maxFileSize) {
        await _fileManager.archiveLogFile(fileName: baseFileName);
      } else {
        await _fileManager.appendToLogFile(
          fileName: baseFileName,
          content: createLogContent(logMessage, logLevel: logLevel, stacktrace: stacktrace),
        );
      }
    } else {
      await _fileManager.createLogFile(fileName: baseFileName);
      await createLog(
        logMessage,
        logLevel: logLevel,
        stacktrace: stacktrace,
      );
    }
  }

  String createLogContent(
    String message, {
    LogLevel logLevel = LogLevel.INFO,
    StackTrace? stacktrace,
  }) {
    final now = DateTime.now();
    final timestamp = '${now.toIso8601String()} | ';

    String combinedMessage = addTimeStampOnEveryNewLine('${logLevel.name} | $message', timestamp);
    if (stacktrace != null) {
      combinedMessage += '\n${addTimeStampOnEveryNewLine(stacktrace.toString(), timestamp)}';
    }
    return '$combinedMessage\n';
  }

  String addTimeStampOnEveryNewLine(String content, String timestamp) {
    return content.split('\n').map((line) => '$timestamp$line').join('\n');
  }

  String getBaseFileName() {
    final now = DateTime.now();
    String baseFileName = '${now.year}${now.month}';
    switch (logGroup) {
      case LogGroups.daily:
        baseFileName += '${now.day}';
        break;
      case LogGroups.everyTwoDays:
        baseFileName += '${(now.day ~/ 2) + 1}';
        break;
      case LogGroups.everyThreeDays:
        baseFileName += '${(now.day ~/ 3) + 1}';
        break;
      case LogGroups.weekly:
        baseFileName += '${(now.day ~/ 8) + 1}';
      case LogGroups.biWeekly:
        baseFileName += '${(now.day ~/ 16) + 1}';
        break;
      case LogGroups.monthly:
        break;
    }
    return baseFileName;
  }
}
