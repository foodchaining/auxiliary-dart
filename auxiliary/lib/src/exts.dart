/*
  Copyright: (C) 2025 foodchaining
  License: BSD 3-Clause "New" or "Revised" License
*/

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:async/async.dart";
import "package:dartz/dartz.dart";
import "package:intl/message_format.dart";
import "package:quiver/check.dart";

///////////////////////////////////////////////////////////////////////////////

extension XStreamObject<T extends Object> on Stream<T> {
  ////
  StreamSubscription<T> xSubscribe(void Function(T) listener) =>
      listen(listener, onError: (Object _) {});
}

extension XSinkObject<T extends Object> on Sink<T> {
  ////
  void xFire(T event) => add(event);
}

extension XStreamVoid on Stream<void> {
  ////
  StreamSubscription<void> xSubscribe(void Function() listener) =>
      listen((_) => listener(), onError: (Object _) {});
}

extension XSinkVoid on Sink<void> {
  ////
  void xFire() => add(null);
}

extension XMapObjectObject<K extends Object, V extends Object> on Map<K, V> {
  ////
  void xInsert(K key, V value) =>
      update(key, (_) => throw ArgumentError(), ifAbsent: () => value);

  V xInsertIfAbsent(K key, V value) => putIfAbsent(key, () => value);

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

  bool xAssignIfNotNull(K key, V? value) =>
      value != null && xAssign(key, value);

  void xUpdate(K key, V value) => update(key, (_) => value);

  void xRemove(K key) => checkState(remove(key) != null);
}

extension XIMapObjectObject<K extends Object, V extends Object> on IMap<K, V> {
  ////
  IMap<K, V> xPutIfNotNull(K key, V? value) =>
      value == null ? this : put(key, value);
}

extension XIterableNObject<T extends Object?> on Iterable<T> {
  ////
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

extension XIListObject<T extends Object> on IList<T> {
  ////
  T get xSingle => toIterable().single;
  T? get xSingleOrNull => toIterable().singleOrNull;
  T get xFirst => headOption.toNullable()!;
  T get xSecond => tailOption.toNullable()!.xFirst;
}

extension XMessageFormat on MessageFormat {
  ////
  String xFormat(List<Object> parameters) => format(
    parameters.asMap().map((var k, var v) => MapEntry(k.toString(), v)),
  );
}

extension XResultObject<T extends Object> on Result<T> {
  ////
  T? get xSuccess => asValue?.value;
  Object? get xOutband => asError?.error;
}

extension XUri on Uri {
  ////
  bool xIsEmpty() => this == empty;

  static final Uri empty = Uri();
}

extension XXObject<X extends Object> on X {
  ////
  T? xTry<T extends Object>() => this is T ? this as T : null;
}

extension XDateTime on DateTime {
  ////
  String xToIsoString() => toUtc().toIso8601String();

  static DateTime now() => DateTime.timestamp();
  static DateTime parse(String str) => DateTime.parse(str).toUtc();
  static DateTime? tryParse(String str) => DateTime.tryParse(str)?.toUtc();
  static DateTime fromMillisecondsSinceEpoch(int millisecondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true);
  static DateTime fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch) =>
      DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: true);
}

extension XRandomAccessFile on RandomAccessFile {
  ////
  void xWriteUint8(int i) => writeByteSync(i);

  int xReadUint8() => readByteSync();

  void xWriteInt32(int i) {
    var data = ByteData(4);
    data.setInt32(0, i);
    writeFromSync(data.buffer.asUint8List());
  }

  int xReadInt32() {
    var data = ByteData(4);
    readIntoSync(data.buffer.asUint8List());
    return data.getInt32(0);
  }

  void xWriteInt64(int i) {
    var data = ByteData(8);
    data.setInt64(0, i);
    writeFromSync(data.buffer.asUint8List());
  }

  int xReadInt64() {
    var data = ByteData(8);
    readIntoSync(data.buffer.asUint8List());
    return data.getInt64(0);
  }

  void xWriteFloat64(double f) {
    var data = ByteData(8);
    data.setFloat64(0, f);
    writeFromSync(data.buffer.asUint8List());
  }

  double xReadFloat64() {
    var data = ByteData(8);
    readIntoSync(data.buffer.asUint8List());
    return data.getFloat64(0);
  }

  void xWriteString(String s) {
    var bytes = utf8.encode(s);
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  String xReadString() {
    int length = xReadInt32();
    var bytes = readSync(length);
    return utf8.decode(bytes);
  }

  void xWriteTime(DateTime time) => xWriteInt64(time.microsecondsSinceEpoch);

  DateTime xReadTime() => XDateTime.fromMicrosecondsSinceEpoch(xReadInt64());

  void xWriteUint32List(Uint32List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  Uint32List xReadUint32List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    return bytes.buffer.asUint32List();
  }

  void xWriteUint16List(Uint16List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  Uint16List xReadUint16List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    return bytes.buffer.asUint16List();
  }

  void xWriteFloat32List(Float32List list) {
    var bytes = list.buffer.asUint8List();
    xWriteInt32(bytes.length);
    writeFromSync(bytes);
  }

  Float32List xReadFloat32List() {
    var length = xReadInt32();
    Uint8List bytes = readSync(length);
    return bytes.buffer.asFloat32List();
  }
}

///////////////////////////////////////////////////////////////////////////////
