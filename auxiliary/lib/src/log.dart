// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:quiver/check.dart";
import "package:quiver_log/log.dart";

import "defs.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// An instance of [Logger].
///
/// This property is initialized by [dartSetupLogging]. It provides convenient
/// access to the logging functionality for libraries and applications.
late final Logger log;

/// A function that prints a message to the console.
///
/// This property is initialized by [dartSetupLogging]. It is analogous to
/// Flutter's
/// [debugPrint](https://api.flutter.dev/flutter/foundation/debugPrint.html)
/// property.
late final DartDebugPrintCallback dartDebugPrint;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A function signature for values of the [dartDebugPrint] property.
///
/// It is analogous to Flutter's
/// [DebugPrintCallback](https://api.flutter.dev/flutter/foundation/DebugPrintCallback.html)
/// typedef.
typedef DartDebugPrintCallback =
    void Function(String? message, {int? wrapWidth});

/// A default implementation of [DartDebugPrintCallback] for [dartDebugPrint].
///
/// This function calls [print] to perform the actual printing. The [wrapWidth]
/// argument is ignored.
// ignore: avoid_print
void dartDebugPrinter(String? message, {int? wrapWidth}) => print(message);

/// Configures the logging functionality of this library.
///
/// This function initializes the [log] and [dartDebugPrint] properties. The
/// [log]'s [Logger] is created or found using the given [name], and is directed
/// to output messages via a [SplittingPrintAppender]. The given [printer] is
/// assigned to [dartDebugPrint]. The [Logger.root]'s level is set to
/// [Level.ALL] in debug mode or [Level.CONFIG] otherwise.
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

/// Formats log messages using a simple pattern.
///
/// The following pattern is used for formatting:
/// > `yyMMdd HH:MM:ss.S level sequence loggerName message`
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

/// Appends string messages to the console using [dartDebugPrint].
///
/// This class uses a [LogFormatter] internally for message formatting. Each
/// message is split into lines; empty lines are ignored. Non-empty lines are
/// printed via [dartDebugPrint], with the `wrapWidth` argument set to `1000`.
base class SplittingPrintAppender extends Appender {
  ///
  /// Creates a new [SplittingPrintAppender] instance.
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
