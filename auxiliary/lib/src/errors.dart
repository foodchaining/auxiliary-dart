/*
  Copyright: (C) 2025 foodchaining
  License: BSD 3-Clause "New" or "Revised" License
*/

import "dart:io";

import "package:meta/meta.dart";
import "package:quiver/check.dart";
import "package:stack_trace/stack_trace.dart";
import "package:synchronized/synchronized.dart";

import "defs.dart";
import "log.dart";

///////////////////////////////////////////////////////////////////////////////

bool _globalGateClosed = false;

bool get globalGateClosed => _globalGateClosed;

///////////////////////////////////////////////////////////////////////////////

void closeGlobalGate() {
  var closing = !_globalGateClosed;
  _globalGateClosed = true;
  if (closing) ////
    log.severe("Global Gate was closed");
}

@pragma("vm:notify-debugger-on-exception")
T gated<T extends Object?>(ComputationSync<T> computation) {
  if (!globalGateClosed)
    try {
      return computation();
    } catch (_) {
      closeGlobalGate();
      rethrow;
    }
  else
    throw GateError();
}

@pragma("vm:notify-debugger-on-exception")
Future<T> gatedAsync<T extends Object?>(Computation<T> computation) async {
  if (!globalGateClosed)
    try {
      return await computation();
    } catch (_) {
      closeGlobalGate();
      rethrow;
    }
  else
    throw GateError();
}

Future<T> later<T extends Object?>(Computation<T> computation) =>
    Future<T>.delayed(Duration.zero, () => gatedAsync<T>(computation));

Future<T> alone<T extends Object?>(Lock lock, Computation<T> computation) =>
    lock.synchronized<T>(() => later<T>(computation));

@pragma("vm:notify-debugger-on-exception")
T finalize<T extends Object?>(
  ComputationSync<T> computation, {
  required ComputationSync<void> finale,
}) {
  T result;
  try {
    result = computation();
  } on Exception {
    finale();
    rethrow;
  }
  finale();
  return result;
}

@pragma("vm:notify-debugger-on-exception")
Future<T> finalizeAsync<T extends Object?>(
  Computation<T> computation, {
  required Computation<void> finale,
}) async {
  T result;
  try {
    result = await computation();
  } on Exception {
    await finale();
    rethrow;
  }
  await finale();
  return result;
}

Never afterFatalErrorExit() => exit(1);

StackTrace? terseStackTrace(StackTrace? stackTrace) =>
    stackTrace == null ? null : Trace.from(stackTrace).terse.vmTrace;

///////////////////////////////////////////////////////////////////////////////

@immutable
base class GateError extends RuntimeError<GateError> {}

@immutable
base class RuntimeException<T extends RuntimeException<T>>
    implements Exception {
  RuntimeException([this.message]);

  @override
  String toString() => message == null ? "$T" : "$T: $message";

  final Object? message;
}

@immutable
base class RuntimeError<T extends RuntimeError<T>> extends Error {
  RuntimeError([this.message]);

  @override
  String toString() =>
      message == null ? "$T" : "$T: ${Error.safeToString(message)}";

  final Object? message;
}

@immutable
base mixin WrappingThrowable {
  @override
  String toString() => "${super.toString()} <= [$throwable]";

  late final Object throwable;
  late final StackTrace throwableStackTrace;
}

@immutable
base class WrappingException extends RuntimeException<WrappingException>
    with WrappingThrowable {
  WrappingException(Object throwable, StackTrace throwableStackTrace) {
    checkState(throwable is! WrappingThrowable);
    this.throwable = throwable;
    this.throwableStackTrace = throwableStackTrace;
  }

  static WrappingException wrap(Object x, StackTrace st) =>
      x is WrappingThrowable
          ? (x is WrappingException
              ? x
              : WrappingException(x.throwable, x.throwableStackTrace))
          : WrappingException(x, st);
}

@immutable
base class WrappingError extends RuntimeError<WrappingError>
    with WrappingThrowable {
  WrappingError(Object throwable, StackTrace throwableStackTrace) {
    checkState(throwable is! WrappingThrowable);
    this.throwable = throwable;
    this.throwableStackTrace = throwableStackTrace;
  }

  static WrappingError wrap(Object x, StackTrace st) =>
      x is WrappingThrowable
          ? (x is WrappingError
              ? x
              : WrappingError(x.throwable, x.throwableStackTrace))
          : WrappingError(x, st);
}

///////////////////////////////////////////////////////////////////////////////
