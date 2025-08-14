// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:async/async.dart";
import "package:dartz/dartz.dart";
import "package:intl/message_format.dart";
import "package:meta/meta.dart";
import "package:quiver/check.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// Extensions on `Stream<extends Object>` objects.
extension XStreamObject<T extends Object> on Stream<T> {
  ///
  /// Calls [listen] with the given [listener]; stream errors are caught and
  /// ignored.
  StreamSubscription<T> xSubscribe(void Function(T) listener) =>
      listen(listener, onError: (Object _) {});
}

/// Extensions on `Sink<extends Object>` objects.
extension XSinkObject<T extends Object> on Sink<T> {
  ///
  /// Calls [add] with the given [event].
  void xFire(T event) => add(event);
}

/// Extensions on `Stream<void>` objects.
extension XStreamVoid on Stream<void> {
  ///
  /// Calls [listen] with the given [listener]; stream errors are caught and
  /// ignored.
  StreamSubscription<void> xSubscribe(void Function() listener) =>
      listen((_) => listener(), onError: (Object _) {});
}

/// Extensions on `Sink<void>` objects.
extension XSinkVoid on Sink<void> {
  ///
  /// Calls [add] with `null` as the argument.
  void xFire() => add(null);
}

/// Extensions on `Map<extends Object, extends Object>` objects.
extension XMapObjectObject<K extends Object, V extends Object> on Map<K, V> {
  ///
  /// Adds the given [key]-[value] pair to the map as a new entry.
  ///
  /// The given [key] must not already be present in the map; otherwise, an
  /// [ArgumentError] will be thrown.
  void xInsert(K key, V value) =>
      update(key, (_) => throw ArgumentError(), ifAbsent: () => value);

  /// Adds the given [key]-[value] pair to the map if the key is new.
  ///
  /// First, it tries to look up the value already associated  with the given
  /// [key] in the map. If the map does not contain the key, it performs the add
  /// operation. The value associated with the key is returned, whether it was
  /// already present or newly inserted.
  V xInsertIfAbsent(K key, V value) => putIfAbsent(key, () => value);

  /// Associates the given [key] with the given [value] in the map.
  ///
  /// Returns whether the key was newly inserted.
  bool xAssign(K key, V value) {
    bool added = false;
    update(
      key,
      (_) => value,
      ifAbsent: () {
        added = true;
        return value;
      },
    );
    return added;
  }

  /// Associates the given [key] with the given non-null [value] in the map.
  ///
  /// Returns whether the key was newly inserted.
  bool xAssignIfNotNull(K key, V? value) =>
      value != null && xAssign(key, value);

  /// Associates the given [key] with the given [value] in the map.
  ///
  /// The key must be already present in the map; otherwise, an [ArgumentError]
  /// will be thrown.
  void xUpdate(K key, V value) => update(key, (_) => value);

  /// Removes the given [key] and its associated value from the map.
  ///
  /// The key must be present in the map; otherwise, a [StateError] will be
  /// thrown.
  void xRemove(K key) => checkState(remove(key) != null);
}

/// Extensions on `IMap<extends Object, extends Object>` objects.
extension XIMapObjectObject<K extends Object, V extends Object> on IMap<K, V> {
  ///
  /// Associates the given [key] with the given non-null [value] in the map.
  ///
  /// If [value] is null, returns the same [IMap] instance.
  IMap<K, V> xPutIfNotNull(K key, V? value) =>
      value == null ? this : put(key, value);
}

/// Extensions on `Iterable<extends Object?>` objects.
extension XIterableNObject<T extends Object?> on Iterable<T> {
  ///
  /// Creates a [List] containing the elements of the [Iterable].
  ///
  /// If [length] is greater than `-1`, the iterable must contain at least
  /// [length] elements; these elements will be included in the resulting list.
  /// The list is fixed-length if [growable] is false.
  List<T> xToList({int length = -1, bool growable = false}) {
    checkState(length >= -1);
    if (length < 0) ////
      return toList(growable: growable);
    Iterator<T> it = iterator;
    return List<T>.generate(length, (_) {
      checkState(it.moveNext());
      return it.current;
    }, growable: growable);
  }
}

/// Extensions on `IList<extends Object>` objects.
extension XIListObject<T extends Object> on IList<T> {
  ///
  /// The first and the only element of the [IList].
  T get xSingle => toIterable().single;

  /// The first and only element of the [IList], or `null`.
  ///
  /// Returns `null` if the list's length is not `1`.
  T? get xSingleOrNull => toIterable().singleOrNull;

  /// The first element of the [IList].
  T get xFirst => headOption.toNullable()!;

  /// The second element of the [IList].
  T get xSecond => tailOption.toNullable()!.xFirst;
}

/// Extensions on `MessageFormat` objects.
extension XMessageFormat on MessageFormat {
  ///
  /// Calls [format] using [parameters] as values, with their indexes as keys.
  ///
  /// Indexes are zero-based; for example, a pattern `{0} plus {1} equals {2}`
  /// refers sequentially to the first, second, and third elements of the
  /// [parameters] list.
  String xFormat(List<Object> parameters) => format(
    parameters.asMap().map((var k, var v) => MapEntry(k.toString(), v)),
  );
}

/// Extensions on `Result<extends Object>` objects.
extension XResultObject<T extends Object> on Result<T> {
  ///
  /// Returns [ValueResult.value] if this [Result] is a [ValueResult].
  ///
  /// Return `null` if this [Result] is not a [ValueResult].
  T? get xSuccess => asValue?.value;

  /// Returns [ErrorResult.error] if this [Result] is an [ErrorResult].
  ///
  /// Return `null` if this [Result] is not an [ErrorResult].
  Object? get xOutband => asError?.error;
}

/// Extensions on `Uri` objects.
extension XUri on Uri {
  ///
  /// Whether this [Uri] is empty.
  bool xIsEmpty() => this == empty;

  /// An instance of an empty [Uri].
  static final Uri empty = Uri();
}

/// Extensions on `extends Object` objects.
extension XXObject<X extends Object> on X {
  ///
  /// Returns `this` as [T] if `this` is [T]; returns `null` otherwise.
  T? xTry<T extends Object>() => this is T ? this as T : null;
}

/// Extensions on `DateTime` objects.
extension XDateTime on DateTime {
  ///
  /// Converts this [DateTime] to UTC and calls its [toIso8601String].
  String xToIsoString() => toUtc().toIso8601String();

  /// Calls [DateTime.timestamp].
  static DateTime now() => DateTime.timestamp();

  /// Calls [DateTime.parse] and converts the result to UTC.
  static DateTime parse(String str) => DateTime.parse(str).toUtc();

  /// Calls [DateTime.tryParse] and converts the result to UTC.
  static DateTime? tryParse(String str) => DateTime.tryParse(str)?.toUtc();

  /// Calls [DateTime.fromMillisecondsSinceEpoch] with `isUtc` set to `true`.
  static DateTime fromMillisecondsSinceEpoch(int millisecondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true);

  /// Calls [DateTime.fromMicrosecondsSinceEpoch] with `isUtc` set to `true`.
  static DateTime fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch) =>
      DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: true);
}

/// Extensions on `RandomAccessFile` objects.
extension XRandomAccessFile on RandomAccessFile {
  ///
  /// Synchronously writes a single byte to the file.
  void xWriteUint8(int i) => checkState(writeByteSync(i) == 1);

  /// Synchronously reads a single byte from the file.
  int xReadUint8() {
    var byte = readByteSync();
    checkInput(byte != -1);
    return byte;
  }

  /// Synchronously writes a 32-bit integer to the file.
  void xWriteInt32(int i) {
    var data = ByteData(4);
    data.setInt32(0, i);
    writeFromSync(data.buffer.asUint8List());
  }

  /// Synchronously reads a 32-bit integer from the file.
  int xReadInt32() {
    var data = ByteData(4);
    checkInput(readIntoSync(data.buffer.asUint8List()) == 4);
    return data.getInt32(0);
  }

  /// Synchronously writes a 64-bit integer to the file.
  void xWriteInt64(int i) {
    var data = ByteData(8);
    data.setInt64(0, i);
    writeFromSync(data.buffer.asUint8List());
  }

  /// Synchronously reads a 64-bit integer from the file.
  int xReadInt64() {
    var data = ByteData(8);
    checkInput(readIntoSync(data.buffer.asUint8List()) == 8);
    return data.getInt64(0);
  }

  /// Synchronously writes a [double] to the file.
  void xWriteFloat64(double f) {
    var data = ByteData(8);
    data.setFloat64(0, f);
    writeFromSync(data.buffer.asUint8List());
  }

  /// Synchronously reads a [double] from the file.
  double xReadFloat64() {
    var data = ByteData(8);
    checkInput(readIntoSync(data.buffer.asUint8List()) == 8);
    return data.getFloat64(0);
  }

  /// Synchronously writes a [String] to the file.
  void xWriteString(String s) {
    var bytes = utf8.encode(s);
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  /// Synchronously reads a [String] from the file.
  String xReadString() {
    int length = xReadInt32();
    Uint8List bytes = readSync(length);
    checkInput(bytes.length == length);
    return utf8.decode(bytes);
  }

  /// Synchronously writes a [DateTime] to the file.
  void xWriteTime(DateTime time) => xWriteInt64(time.microsecondsSinceEpoch);

  /// Synchronously reads a [DateTime] from the file.
  DateTime xReadTime() => XDateTime.fromMicrosecondsSinceEpoch(xReadInt64());

  /// Synchronously writes a [Uint32List] to the file.
  void xWriteUint32List(Uint32List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  /// Synchronously reads a [Uint32List] from the file.
  Uint32List xReadUint32List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    checkInput(bytes.length == length);
    return bytes.buffer.asUint32List();
  }

  /// Synchronously writes a [Uint16List] to the file.
  void xWriteUint16List(Uint16List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  /// Synchronously reads a [Uint16List] from the file.
  Uint16List xReadUint16List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    checkInput(bytes.length == length);
    return bytes.buffer.asUint16List();
  }

  /// Synchronously writes a [Float32List] to the file.
  void xWriteFloat32List(Float32List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  /// Synchronously reads a [Float32List] from the file.
  Float32List xReadFloat32List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    checkInput(bytes.length == length);
    return bytes.buffer.asFloat32List();
  }

  /// Throws a [StateError] if the [complete] argument is `false`.
  @protected
  static void checkInput(bool complete) {
    if (!complete) ////
      throw StateError("XRandomAccessFile: incomplete read operation");
  }
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
