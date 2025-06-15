import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:log_manager/log_manager.dart';
import 'package:log_manager/src/io/log_manager_io.dart';
import 'package:log_manager/src/shared/extensions/level_converter.dart';
import 'package:log_manager/src/shared/log_printer.dart';
import 'package:log_manager/src/shared/zone_specs.dart';
import 'package:logging/logging.dart';

class LogManagerCore {
  initLogManagerCore(
      {required Function onAppStart, Function(String message)? onLogCreated, Options options = const Options()}) {
    if (options.preventCrashes) {
      runZonedGuarded(
        () {
          WidgetsFlutterBinding.ensureInitialized();
          initLogManagerIO(options);
          initLogging(options);
          initFlutterErrorHandler(options, onLogCreated);
          onAppStart();
        },
        (error, stack) => catchUnhandledExceptions(error, stack, options, onLogCreated),
        zoneSpecification: ZoneSpecs.defaultZoneSpecification(
          prettyPrint: options.prettyPrint,
          logToFile: options.logToFile,
        ), // Use the default zone specification
      );
    } else {
      runZoned(() {
        WidgetsFlutterBinding.ensureInitialized();
        initFlutterErrorHandler(options, onLogCreated);
        onAppStart();
      });
    }
  }

  void initLogManagerIO(Options options) {
    if (options.logToFile) {
      LogManager.logManagerIO = LogManagerIO(writeToDownloadsDirectory: options.writeLogsToDownloadsDirectory);
      LogManager.logManagerIO!.init();
    }
  }

  void initLogging(Options options) {
    Logger.root.level = Level.ALL; // Set the root logger level to ALL
    Logger.root.onRecord.listen((record) {
      LogPrinter.print(record.message, pretty: options.prettyPrint, label: record.loggerName);
      if (options.logToFile) {
        if (LogManager.getLogManagerIO() != null) {
          LogManager.getLogManagerIO()?.createLog(
            record.message,
            logLevel: record.level.toLogLevel(),
            stacktrace: record.stackTrace,
          );
        }
      }
    });
  }

  void initFlutterErrorHandler(Options options, Function(String message)? onLogCreated) {
    FlutterError.onError = (FlutterErrorDetails details) {
      catchUnhandledExceptions(details.exception, details.stack, options, onLogCreated);
    };
  }

  Future<void> catchUnhandledExceptions(
    Object error,
    StackTrace? stack,
    Options options,
    Function(String message)? onLogCreated,
  ) async {
    LogPrinter.printStack(stackTrace: stack, label: error.toString(), pretty: options.prettyPrint);
    if (options.logToFile) {
      if (LogManager.getLogManagerIO() != null) {
        LogManager.getLogManagerIO()?.createLog(
          error.toString(),
          logLevel: LogLevel.ERROR,
          stacktrace: stack,
        );
      }
    }
  }
}
