// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
import "package:crypto/crypto.dart";
import "package:equatable/equatable.dart";
import "package:intl/message_format.dart";
import "package:meta/meta.dart";
import "package:nanoid/nanoid.dart";
import "package:quiver/check.dart";
import "package:rxdart/rxdart.dart";

import "exts.dart";
import "log.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A constant that is `true` if the application was compiled in the debug mode.
///
/// Is an analogue of the Flutter's
/// [kDebugMode](https://api.flutter.dev/flutter/foundation/kDebugMode-constant.html)
/// constant.
const bool kDartDebugMode = !kDartReleaseMode && !kDartProfileMode;

/// A constant that is `true` if the application was compiled in the profile
/// mode.
///
/// Is an analogue of the Flutter's
/// [kProfileMode](https://api.flutter.dev/flutter/foundation/kProfileMode-constant.html)
/// constant.
const bool kDartProfileMode = bool.fromEnvironment("dart.vm.profile");

/// A constant that is `true` if the application was compiled in the release
/// mode.
///
/// Is an analogue of the Flutter's
/// [kReleaseMode](https://api.flutter.dev/flutter/foundation/kReleaseMode-constant.html)
/// constant.
const bool kDartReleaseMode = bool.fromEnvironment("dart.vm.product");

/// A constant string of a single non-breaking space character.
///
/// The character's unicode hexadecimal encoding is `U+00A0`.
const String nbsp = "\u00A0";

/// A constant of a [double] value equal to `1.0E+9`.
///
/// This is the right boundary of the entire coordinate space, as defined in the
/// Flutter's
/// [Rect.largest](https://api.flutter.dev/flutter/dart-ui/Rect/largest-constant.html)
/// constant.
const double giantScalar = 1.0E+9;

/// A constant of a [double] value equal to `1 / 1.0E+9`.
///
/// This is a reciprocal for the [giantScalar].
const double epsilon = 1 / giantScalar;

/// Whether the application is running on a desktop operating system.
///
/// Is `true` if either [Platform.isWindows], [Platform.isMacOS] or
/// [Platform.isLinux] is `true`.
@pragma("vm:platform-const")
final bool isDesktopPlatform =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// A [DateTime] pointing to `0001-01-01 00:00:00.000Z`
final DateTime zeroTime = DateTime.utc(1);

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A signature of a typical synchronous or asynchronous callback.
typedef Computation<T extends Object?> = FutureOr<T> Function();

/// A signature of a typical synchronous callback.
typedef ComputationSync<T extends Object?> = T Function();

/// A signature of a typical asynchronous callback.
typedef ComputationAsync<T extends Object?> = Future<T> Function();

/// A specialization of the [Comparable] interface for non-nullable [Object]s.
typedef Ordered<T extends Object> = Comparable<T>;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// Prevents compilation if the argument is not [Enum].
void checkEnum<T extends Enum>(T _) {}

/// A [Future] that completes no sooner than in the next event-loop iteration.
Future<void> cooperate() => Future<Object?>.delayed(Duration.zero);

/// Calls [Comparable.compareTo] on the [Ordered] arguments.
int compare1<T extends Ordered>(T v1, T v2) => v1.compareTo(v2);

/// Compares two pairs of [Ordered] values, defining an ordering of pairs.
///
/// Returns a negative integer if `(a1, b1)` is ordered before `(a2, b2)`, a
/// positive integer if `(a1, b1)` is ordered after `(a2, b2)`, and zero if
/// `(a1, b1)` and `(a2, b2)` are ordered together.
int compare2<A extends Ordered, B extends Ordered>(A a1, B b1, A a2, B b2) {
  int cmp = compare1(a1, a2);
  return cmp != 0 ? cmp : compare1(b1, b2);
}

/// Returns a string representation of a [num] preferring no decimal point.
///
/// If the given `n` could be converted to an equal [int], returns the
/// representation of the `n` without a decimal point. Otherwise calls
/// [num.toString] if the `fd` is `-1` or, if not, calls [num.toStringAsFixed]
/// with the `fd` argument.
String numToString(num n, [int fd = -1]) {
  int ni = n.toInt();
  return ni == n ? "$ni" : (fd == -1 ? "$n" : n.toStringAsFixed(fd));
}

/// Formats a [MessageFormat] `pattern` using positional `parameters`.
String format(
  String pattern,
  List<Object> parameters, [
  String locale = "en",
]) => MessageFormat(pattern, locale: locale).xFormat(parameters);

/// Separates items of the `iterable` with results of calls to the `separator`.
///
/// The function generates a new [Iterable] where every pair of neighboring
/// items in the given `iterable` is separated by a result of a distinct call to
/// the `separator` function.
Iterable<T> separate<T extends Object>(
  Iterable<T> iterable,
  T Function() separator,
) sync* {
  var it = iterable.iterator;
  if (it.moveNext()) {
    yield it.current;
    while (it.moveNext()) {
      yield separator();
      yield it.current;
    }
  }
}

/// Creates a [Stream] of byte chunks out of a [List] of bytes.
///
/// The functions splits the given list of `bytes` into pages using the given
/// `page` size and returns these pages as a new [Stream] of byte chunks.
Stream<List<int>> bytesToStream(List<int> bytes, {int page = 4096}) =>
    Stream<List<int>>.fromIterable(bytes.slices(page));

/// Returns a string of random ASCII alphanumeric characters.
///
/// The size of the returned string is defined by the given `size` argument.
String randomFilename([int size = 20]) =>
    customAlphabet("0123456789abcdefghijklmnopqrstuvwxyz", size);

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// The size in bytes of a 384-bit hash.
const int fullHashByteLength = 48;

/// The size of a base36 representation of a 384-bit hash.
const int fullHashCharLength = 75;

/// The size in bytes of a 64-bit hash.
const int shortHashByteLength = 8;

/// The size of a base36 representation of a 64-bit hash.
const int shortHashCharLength = 13;

/// Returns a base36 representation of the given [List] of `bytes`.
String base36String(List<int> bytes) {
  var hex = bytes.map((var c) => c.toRadixString(16).padLeft(2, "0")).join();
  checkState(hex.length == bytes.length * 2);
  return BigInt.parse(hex, radix: 16).toRadixString(36);
}

/// For the given string returns its SHA-384 hash as a [List] of bytes.
List<int> byteHashOfString(String str) =>
    sha384.convert(utf8.encode(str)).bytes;

/// For the given string returns its SHA-384 hash in a base36 representation.
String fullHashOfString(String str) =>
    base36String(byteHashOfString(str)).padLeft(fullHashCharLength, "0");

/// For the given string returns its 64-bit hash in a base36 representation.
///
/// The 64-bit hash is formed as first 8 bytes of an SHA-384 hash.
String shortHashOfString(String str) => base36String(
  byteHashOfString(str).sublist(0, shortHashByteLength),
).padLeft(shortHashCharLength, "0");

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// An object that is only equal to itself.
@immutable
final class UniqueObject {
  ///
  /// Creates an object that is equal only to itself.
  UniqueObject();
}

/// A mixin that overrides the [EquatableMixin.stringify] property as `true`.
@immutable
base mixin Stringified on EquatableMixin {
  ///
  /// Overrides the [EquatableMixin.stringify] property as `true`.
  @override
  bool get stringify => true;

  /// Returns a string representation of the [props] list.
  String toPropsString() => props.map((var p) => "$p").join(", ");
}

/// A mixin that defines the index-based ordering for values of an [Enum].
@immutable
base mixin OrderedEnum<TEnum extends Enum> on Enum
    implements Comparable<TEnum> {
  ///
  /// Whether `this` enum index is less than `that` enum index.
  bool operator <(TEnum that) => index < that.index;

  /// Whether `this` enum index is greater than `that` enum index.
  bool operator >(TEnum that) => index > that.index;

  /// Whether `this` enum index is less than or equal to `that` enum index.
  bool operator <=(TEnum that) => index <= that.index;

  /// Whether `this` enum index is greater than or equal to `that` enum index.
  bool operator >=(TEnum that) => index >= that.index;

  @override
  int compareTo(TEnum that) => Enum.compareByIndex(this, that);
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A [Stream]-based Finite State Machine implementation.
///
/// The class is parametrized by the state type [S] and the event type [E].
base class StateMachine<S extends Object, E extends Object> {
  ///
  /// Creates a [StateMachine] and sets it to the `initial` state. The given
  /// `logging` argument controls how to log state transitions.
  ///
  /// If the given `logging` is `null`, there are no state transition log
  /// messages. If the `logging` is not an empty string, log messages are
  /// prefixed with the `logging` as a prefix. If the `logging` is an empty
  /// string, log messages do not have a prefix.
  ///
  /// The log message format is `[Prefix, ]Event: State -> NewState`.
  StateMachine(S initial, {String? logging = ""}) : _logging = logging {
    _state.xFire(initial);
  }

  /// Frees resources of this [StateMachine] instance.
  void close() => _state.close();

  /// Defines a transition from the `origin` to the `target` by the `event`.
  void let(E event, S origin, S target) {
    var stateEvents = _events[origin] ?? (_events[origin] = HashMap<E, S>());
    stateEvents[event] = target;
  }

  /// Subscribes the `callback` to the given `trigger` state.
  ///
  /// The `callback` will be called when this [StateMachine] enters the
  /// `trigger` state.
  ///
  /// Returns a [StreamSubscription] object that can cancel the `callback`
  /// subscription.
  StreamSubscription<S> subscribe(S trigger, ComputationSync<void> callback) =>
      stream.where((var s) => s == trigger).xSubscribe((_) => callback());

  /// Sends the `event` to this [StateMachine].
  void feed(E event) {
    var target = _events[state]?[event];
    checkState(
      target != null,
      message: "Event $event undefined for state $state",
    );
    if (_logging != null) {
      String message = "$event: $state -> $target";
      if (_logging.isNotEmpty) //
        message = "$_logging, $message";
      log.finest(message);
    }
    _state.xFire(target!);
  }

  /// A current state of this [StateMachine].
  S get state => _state.value;

  /// A stream of states of this [StateMachine].
  Stream<S> get stream => _state.stream;

  final Map<S, Map<E, S>> _events = HashMap();
  final _state = BehaviorSubject<S>();
  final String? _logging;
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
