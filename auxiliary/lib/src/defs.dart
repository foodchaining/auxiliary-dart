/*
  Copyright: (C) 2025 foodchaining
  License: BSD 3-Clause "New" or "Revised" License
*/

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

///////////////////////////////////////////////////////////////////////////////

const bool kDartDebugMode = !kDartReleaseMode && !kDartProfileMode;
const bool kDartProfileMode = bool.fromEnvironment("dart.vm.profile");
const bool kDartReleaseMode = bool.fromEnvironment("dart.vm.product");

const String nbsp = "\u00A0";

const double giantScalar = 1.0E+9;
const double epsilon = 1 / giantScalar;

@pragma("vm:platform-const")
final bool isDesktopPlatform =
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

final DateTime zeroTime = DateTime.utc(1);

final reNotAlNum = RegExp("[^\\p{L}\\p{N}]+", unicode: true);
final reNotAlNumSp = RegExp("[^\\p{L}\\p{N} ]+", unicode: true);

///////////////////////////////////////////////////////////////////////////////

typedef Computation<T extends Object?> = FutureOr<T> Function();
typedef ComputationSync<T extends Object?> = T Function();
typedef ComputationAsync<T extends Object?> = Future<T> Function();

typedef Index<T extends Object> = Comparable<T>;

///////////////////////////////////////////////////////////////////////////////

void checkEnum<T extends Enum>(T _) {}

Future<void> cooperate() => Future<Object?>.delayed(Duration.zero);

int compare1<T extends Index>(T v1, T v2) => v1.compareTo(v2);

int compare2<A extends Index, B extends Index>(A a1, B b1, A a2, B b2) {
  int cmp = compare1(a1, a2);
  return cmp != 0 ? cmp : compare1(b1, b2);
}

String numToString(num n, [int fd = -1]) {
  int ni = n.toInt();
  return ni == n ? "$ni" : (fd == -1 ? "$n" : n.toStringAsFixed(fd));
}

String format(
  String pattern,
  List<Object> parameters, [
  String locale = "en",
]) => MessageFormat(pattern, locale: locale).xFormat(parameters);

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

Stream<List<int>> bytesToStream(List<int> bytes, {int page = 4096}) =>
    Stream<List<int>>.fromIterable(bytes.slices(page));

String randomFilename([int size = 20]) =>
    customAlphabet("0123456789abcdefghijklmnopqrstuvwxyz", size);

///////////////////////////////////////////////////////////////////////////////

const int fullHashByteLength = 48;
const int fullHashCharLength = 75;
const int shortHashByteLength = 8;
const int shortHashCharLength = 13;

String base36String(List<int> bytes) {
  var hex = bytes.map((var c) => c.toRadixString(16).padLeft(2, "0")).join();
  checkState(hex.length == bytes.length * 2);
  return BigInt.parse(hex, radix: 16).toRadixString(36);
}

List<int> byteHashOfString(String str) =>
    sha384.convert(utf8.encode(str)).bytes;

String fullHashOfString(String str) =>
    base36String(byteHashOfString(str)).padLeft(fullHashCharLength, "0");

String shortHashOfString(String str) => base36String(
  byteHashOfString(str).sublist(0, shortHashByteLength),
).padLeft(shortHashCharLength, "0");

///////////////////////////////////////////////////////////////////////////////

@immutable
final class UniqueObject {
  UniqueObject();
}

@immutable
base mixin Stringified on EquatableMixin {
  @override
  bool get stringify => true;

  String toPropsString() => props.map((var p) => "$p").join(", ");
}

@immutable
base mixin OrderedEnum<TEnum extends Enum> on Enum {
  bool operator <(TEnum e) => index < e.index;
  bool operator >(TEnum e) => index > e.index;
  bool operator <=(TEnum e) => index <= e.index;
  bool operator >=(TEnum e) => index >= e.index;
}

///////////////////////////////////////////////////////////////////////////////

base class StateMachine<S extends Object, E extends Object> {
  StateMachine(S initial, {String? logging = ""}) : _logging = logging {
    _state.xFire(initial);
  }

  void close() => _state.close();

  void let(E event, S origin, S target) {
    var stateEvents = _events[origin] ?? (_events[origin] = HashMap<E, S>());
    stateEvents[event] = target;
  }

  StreamSubscription<S> subscribe(S trigger, ComputationSync<void> callback) =>
      stream.where((var s) => s == trigger).xSubscribe((_) => callback());

  void feed(E event) {
    var target = _events[state]?[event];
    checkState(
      target != null,
      message: "Event $event undefined for state $state",
    );
    if (_logging != null) {
      String message = "$event: $state -> $target";
      if (_logging.isNotEmpty) ////
        message = "$_logging, $message";
      log.finest(message);
    }
    _state.xFire(target!);
  }

  S get state => _state.value;
  Stream<S> get stream => _state.stream;

  final Map<S, Map<E, S>> _events = HashMap();
  final _state = BehaviorSubject<S>();
  final String? _logging;
}

///////////////////////////////////////////////////////////////////////////////
