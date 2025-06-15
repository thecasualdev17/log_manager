import 'package:log_manager/src/core/log_manager_core.dart';
import 'package:log_manager/src/shared/extensions/level_converter.dart';
import 'package:log_manager/src/shared/log_printer.dart';
import 'package:log_manager/src/shared/models/log_level.dart';
import 'package:log_manager/src/shared/models/options.dart';
import 'package:logging/logging.dart';

import '../io/log_manager_io.dart';

class LogManager {
  LogManager._internal();

  static final LogManager _instance = LogManager._internal();

  static LogManagerIO? logManagerIO;

  static Function(String message)? onLogCreated;

  late LogManagerCore logManagerCore;

  factory LogManager() {
    return _instance;
  }

  void init({required Function onAppStart, Function(String message)? onLogCreated, Options options = const Options()}) {
    logManagerCore = LogManagerCore();
    logManagerCore.initLogManagerCore(
      onAppStart: onAppStart,
      onLogCreated: onLogCreated,
      options: options,
    );
  }

  static void log(String message, {LogLevel logLevel = LogLevel.INFO, String identifier = 'log_manager'}) {
    Level level = Level.LEVELS.firstWhere(
      (e) => e.name.toLowerCase() == logLevel.name.toLowerCase(),
      orElse: () => Level.INFO,
    );

    final log = Logger(identifier);
    log.log(level, message);
  }

  static void logWithStack(
    String message, {
    LogLevel logLevel = LogLevel.ERROR,
    String identifier = 'log_manager',
    StackTrace? stacktrace,
  }) {
    final log = Logger(identifier);
    log.log(
      logLevel.toLevel(),
      '$message\nStackTrace:\n$stacktrace',
    );
    LogPrinter.printStack(stackTrace: stacktrace);
  }

  static LogManagerIO? getLogManagerIO() {
    return logManagerIO;
  }

  static void setOnLogCreated(Function(String message) onLogCreated) {
    LogManager.onLogCreated = onLogCreated;
  }
}
