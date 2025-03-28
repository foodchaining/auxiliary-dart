// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:quiver/check.dart";
import "package:quiver_log/log.dart";

import "defs.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

late final Logger log;
late final DartDebugPrintCallback dartDebugPrint;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

typedef DartDebugPrintCallback =
    void Function(String? message, {int? wrapWidth});

// ignore: avoid_print
void dartDebugPrinter(String? message, {int? wrapWidth}) => print(message);

void dartSetupLogging(
  String name, {
  DartDebugPrintCallback printer = dartDebugPrinter,
}) {
  bool debugMode = false;
  assert((() => debugMode = true)());
  checkState(debugMode == kDartDebugMode);
  dartDebugPrint = printer;
  log = Logger(name);
  Logger.root.level = kDartDebugMode ? Level.ALL : Level.CONFIG;
  SplittingPrintAppender().attachLogger(Logger.root);
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

base class LogFormatter implements Formatter {
  //
  @override
  String call(LogRecord record) {
    var message =
        "${_dateFormat.format(record.time)} ${record.level} " +
        "${record.sequenceNumber} ${record.loggerName} ${record.message}";
    if (record.error != null) //
      message = "$message, error: \"${record.error}\"";
    if (record.stackTrace != null) //
      message = "$message\n${record.stackTrace}";
    return message;
  }

  static final _dateFormat = DateFormat("yyMMdd HH:mm:ss.S");
}

base class SplittingPrintAppender extends Appender {
  SplittingPrintAppender() : super(LogFormatter());

  @override
  void append(LogRecord record, Formatter formatter) => formatter
      .call(record)
      .split(SplittingPrintAppender._reCRLF)
      .where((var e) => e.trim().isNotEmpty)
      .forEach((var e) => dartDebugPrint(e, wrapWidth: 1000));

  static final _reCRLF = RegExp("[\r\n]");
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
