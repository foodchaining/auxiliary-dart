// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "dart:async";
import "dart:io";

import "package:meta/meta.dart";
import "package:quiver/check.dart";
import "package:stack_trace/stack_trace.dart";
import "package:synchronized/synchronized.dart";

import "defs.dart";
import "log.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

bool _globalGateClosed = false;

/// Whether the Global Gate is closed.
///
/// The Global Gate is open by default. Once closed, it cannot be reopened, and
/// the program is expected to terminate eventually. The Global Gate should be
/// closed upon a fatal program failure. Such a failure may occur, for example,
/// when an [Error] is thrown.
///
/// The closed Global Gate status indicates that the execution of critical code
/// sections which output data should be avoided. This measure aims to prevent
/// data corruption and can be applied via these Global Gate-aware functions:
/// [gated], [gatedAsync], [later], and [alone].
bool get globalGateClosed => _globalGateClosed;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// Closes the Global Gate if it is not already closed.
///
/// This function ensures that the [globalGateClosed] property is set to `true`.
void closeGlobalGate() {
  var closing = !_globalGateClosed;
  _globalGateClosed = true;
  if (closing) ////
    log.severe("Global Gate was closed");
}

/// Executes synchronous [computation] in a Global Gate‐aware context.
///
/// If the Global Gate is closed, this function throws a [GateError]. Otherwise,
/// it runs [computation] synchronously and, if [computation] throws, closes the
/// Global Gate and rethrows.
///
/// The asynchronous variant of this function is [gatedAsync].
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

/// Executes asynchronous [computation] in a Global Gate‐aware context.
///
/// If the Global Gate is closed, this function throws a [GateError]. Otherwise,
/// it runs [computation] asynchronously and, if [computation] throws, closes
/// the Global Gate and rethrows.
///
/// The synchronous variant of this function is [gated].
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

/// Cooperatively executes a [Computation] in a Global Gate‐aware context.
///
/// This function calls [computation] via [gatedAsync]. The call is scheduled to
/// be performed during the next event-loop iteration.
Future<T> later<T extends Object?>(Computation<T> computation) =>
    Future<T>.delayed(Duration.zero, () => gatedAsync<T>(computation));

/// Exclusively and cooperatively executes a [Computation] in a Global
/// Gate‐aware context.
///
/// This function calls [computation] via [later]. The call is scheduled to be
/// performed during the next event-loop iteration. The call is guarded with
/// [lock]'s [Lock.synchronized] method, which allows only one asynchronous flow
/// to enter [computation] and keeps other contending asynchronous flows waiting
/// for their turn.
Future<T> alone<T extends Object?>(Lock lock, Computation<T> computation) =>
    lock.synchronized<T>(() => later<T>(computation));

/// Synchronously calls [computation] and then [finale] with awareness of
/// [Exception]s.
///
/// This function behaves similarly to a try-finally block. First, it calls the
/// synchronous [computation] function. Then, depending on what is thrown by
/// [computation]⁠: if nothing is thrown, it calls [finale]; if an [Exception]
/// is thrown, it calls [finale] and rethrows the [Exception]; if a different
/// [Object] is thrown, [finale] is not called and the thrown [Object] is not
/// caught.
///
/// The asynchronous variant of this function is [finalizeAsync].
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

/// Asynchronously calls [computation] and then [finale] with awareness of
/// [Exception]s.
///
/// This function behaves similarly to a try-finally block. First, it calls the
/// asynchronous [computation] function. Then, depending on what is thrown by
/// [computation]⁠: if nothing is thrown, it calls [finale]; if an [Exception]
/// is thrown, it calls [finale] and rethrows the [Exception]; if a different
/// [Object] is thrown, [finale] is not called and the thrown [Object] is not
/// caught.
///
/// The synchronous variant of this function is [finalize].
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

/// Calls [exit] with the given [code].
Never afterFatalErrorExit([int code = 1]) => exit(code);

/// Returns a terser version of a [StackTrace].
///
/// This function relies on the [Trace] class and its mechanism for producing a
/// terser version of itself, which is available via [Trace.terse].
StackTrace? terseStackTrace(StackTrace? stackTrace) =>
    stackTrace == null ? null : Trace.from(stackTrace).terse.vmTrace;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// Thrown when the Global Gate is expected to be open but it is not.
@immutable
base class GateError extends RuntimeError {
  @override
  Object get kind => "$GateError";
}

/// A base mixin for the [RuntimeException] and [RuntimeError] classes.
///
/// This mixin introduces the [kind] and [message] properties. A subtype must
/// override [kind] to provide its type information, and may override [message]
/// to describe the cause of the throw.
base mixin RuntimeThrowable {
  @override
  String toString() =>
      message == null ? "$kind" : "$kind: ${Error.safeToString(message)}";

  /// Type information for this [RuntimeThrowable].
  ///
  /// This property must be overridden in subtypes so that the default string
  /// representation from [RuntimeThrowable.toString] is more meaningful.
  @mustBeOverridden
  Object get kind => "$RuntimeThrowable";

  /// A description of the cause of the throw.
  Object? get message;
}

/// A general [Exception] with [kind] and [message].
@immutable
base class RuntimeException with RuntimeThrowable implements Exception {
  ///
  /// Creates a new [RuntimeException] with the given [message].
  RuntimeException([this.message]);

  @override
  Object get kind => "$RuntimeException";

  @override
  final Object? message;
}

/// A general [Error] with [kind] and [message].
@immutable
base class RuntimeError extends Error with RuntimeThrowable {
  ///
  /// Creates a new [RuntimeError] with the given [message].
  RuntimeError([this.message]);

  @override
  Object get kind => "$RuntimeError";

  @override
  final Object? message;
}

/// A base mixin for the [WrappingException] and [WrappingError] classes.
///
/// This mixin introduces the [throwable] and [throwableStackTrace] properties.
/// It is used when a thrown [Object] and its corresponding [StackTrace] must be
/// handled as a single entity. This concept is similar to [AsyncError] but is
/// generalized to include [Exception]s as well.
@immutable
base mixin WrappingThrowable on RuntimeThrowable {
  @override
  String toString() => "${super.toString()} <= [$throwable]";

  /// An [Object] that was thrown.
  Object get throwable;

  /// The [StackTrace] corresponding to the thrown [throwable].
  StackTrace get throwableStackTrace;
}

/// A [RuntimeException] that wraps [throwable] and [throwableStackTrace].
@immutable
base class WrappingException extends RuntimeException with WrappingThrowable {
  ///
  /// Creates a new [WrappingException] from [throwable] and its stack trace.
  ///
  /// The given [throwable] must not be a [WrappingThrowable].
  WrappingException(this.throwable, this.throwableStackTrace) {
    checkState(throwable is! WrappingThrowable);
  }

  @override
  Object get kind => "$WrappingException";

  @override
  final Object throwable;

  @override
  final StackTrace throwableStackTrace;

  /// Unwraps [x] or creates a new [WrappingException] from [x] and [st].
  ///
  /// This function returns [x] if [x] is a [WrappingException], returns a new
  /// [WrappingException] based on [x]'s properties if [x] is a [WrappingError],
  /// or returns a new [WrappingException] from [x] and [st] if [x] is not a
  /// [WrappingThrowable].
  static WrappingException wrap(Object x, StackTrace st) =>
      x is WrappingThrowable
      ? (x is WrappingException
            ? x
            : WrappingException(x.throwable, x.throwableStackTrace))
      : WrappingException(x, st);
}

/// A [RuntimeError] that wraps [throwable] and [throwableStackTrace].
@immutable
base class WrappingError extends RuntimeError with WrappingThrowable {
  ///
  /// Creates a new [WrappingError] from [throwable] and its stack trace.
  ///
  /// The given [throwable] must not be a [WrappingThrowable].
  WrappingError(this.throwable, this.throwableStackTrace) {
    checkState(throwable is! WrappingThrowable);
  }

  @override
  Object get kind => "$WrappingError";

  @override
  final Object throwable;

  @override
  final StackTrace throwableStackTrace;

  /// Unwraps [x] or creates a new [WrappingError] from [x] and [st].
  ///
  /// This function returns [x] if [x] is a [WrappingError], returns a new
  /// [WrappingError] based on [x]'s properties if [x] is a [WrappingException],
  /// or returns a new [WrappingError] from [x] and [st] if [x] is not a
  /// [WrappingThrowable].
  static WrappingError wrap(Object x, StackTrace st) => x is WrappingThrowable
      ? (x is WrappingError
            ? x
            : WrappingError(x.throwable, x.throwableStackTrace))
      : WrappingError(x, st);
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
