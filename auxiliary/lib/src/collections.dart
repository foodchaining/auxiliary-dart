/*
  Copyright: (C) 2025 foodchaining
  License: BSD 3-Clause "New" or "Revised" License
*/

import "dart:collection";

import "package:dartz/dartz.dart";
import "package:equatable/equatable.dart";
import "package:meta/meta.dart";
import "package:quiver/check.dart";
import "package:quiver/collection.dart";

import "defs.dart";
import "exts.dart";

///////////////////////////////////////////////////////////////////////////////

typedef StdList = List<Object?>;
typedef StdMap = Map<Object?, Object?>;

///////////////////////////////////////////////////////////////////////////////

typedef EquatableStdList = EquatableList<Object?>;
typedef EquatableStdMap = EquatableMap<Object?, Object?>;

@immutable
base class EquatableList<T extends Object?> extends UnmodifiableListView<T>
    with EquatableMixin, Stringified {
  EquatableList(List<T> super.source) : props = source;

  @override
  final List<T> props;
}

@immutable
base class EquatableMap<K extends Object?, V extends Object?>
    extends UnmodifiableMapView<K, V>
    with EquatableMixin, Stringified {
  EquatableMap(super.source) : props = [source];

  @override
  final List<Map<K, V>> props;
}

@immutable
base class EquatableSet<T extends Object?> extends UnmodifiableSetView<T>
    with EquatableMixin, Stringified {
  EquatableSet(super.source) : props = [source];

  @override
  final List<Set<T>> props;
}

///////////////////////////////////////////////////////////////////////////////

@immutable
base class LateList<T extends Object?> extends DelegatingList<T> {
  LateList(Iterable<T> iterable, {int length = -1})
    : _iterable = iterable,
      _length = length;

  @override
  late final List<T> delegate = UnmodifiableListView(
    _iterable.xToList(length: _length),
  );

  final Iterable<T> _iterable;
  final int _length;
}

///////////////////////////////////////////////////////////////////////////////

final class SortedMapEntry<K extends Index, V extends Object?> {
  SortedMapEntry(this.key, this.value);
  SortedMapEntry._key(this.key);

  late V value;
  final K key;
}

base class SortedMap<K extends Index, V extends Object?>
    extends IterableBase<SortedMapEntry<K, V>>
    with SetMixin<SortedMapEntry<K, V>> {
  ////
  SortedMap({Comparator<K>? comparator})
    : _treeSet = TreeSet<SortedMapEntry<K, V>>(
        comparator:
            comparator != null
                ? (var a, var b) => comparator(a.key, b.key)
                : (var a, var b) => compare1<K>(a.key, b.key),
      );

  SortedMapEntry<K, V>? operator [](K key) =>
      lookup(SortedMapEntry<K, V>._key(key));

  bool insert(K key, V value) => add(SortedMapEntry<K, V>(key, value));

  bool erase(K key) => remove(SortedMapEntry<K, V>._key(key));

  @override
  Iterator<SortedMapEntry<K, V>> get iterator => _treeSet.iterator;

  @override
  SortedMapEntry<K, V> get last => _treeSet.last;

  @override
  int get length => _treeSet.length;

  @override
  bool add(SortedMapEntry<K, V> entry) => _treeSet.add(entry);

  @override
  void clear() => _treeSet.clear();

  @override
  bool contains(Object? element) => _treeSet.contains(element);

  @override
  SortedMapEntry<K, V>? lookup(Object? element) => _treeSet.lookup(element);

  @override
  bool remove(Object? element) => _treeSet.remove(element);

  Iterator<SortedMapEntry<K, V>> fromIterator(
    K anchor, {
    bool reversed = false,
    bool inclusive = true,
  }) => _treeSet.fromIterator(
    SortedMapEntry<K, V>._key(anchor),
    reversed: reversed,
    inclusive: inclusive,
  );

  final TreeSet<SortedMapEntry<K, V>> _treeSet;
}

///////////////////////////////////////////////////////////////////////////////

@immutable
base class IMultimap<K extends Object, V extends Object?>
    with EquatableMixin, Stringified {
  IMultimap(IMap<K, IList<V>> map) : _map = map;
  IMultimap.empty(Order<K> order) : _map = IMap<K, IList<V>>.empty(order);

  IList<V> getList(K key) => _map.get(key).getOrElse(() => Nil<V>());

  IMultimap<K, V> insert(K key, V value) {
    var list = getList(key);
    list = list.prependElement(value);
    return IMultimap(_map.put(key, list));
  }

  IMultimap<K, V> remove(K key, V value) {
    var list = getList(key);
    bool found = false;
    list = list.filter((var v) {
      if (found)
        return true;
      else {
        if (v == value) {
          found = true;
          return false;
        } else
          return true;
      }
    });
    checkState(found);
    if (list.isEmpty)
      return IMultimap(_map.remove(key));
    else
      return IMultimap(_map.put(key, list));
  }

  @override
  List<Object> get props => [_map];

  final IMap<K, IList<V>> _map;
}

///////////////////////////////////////////////////////////////////////////////

typedef XY = ({int x, int y});

base class Array2D<T extends Object?> {
  Array2D(this.xLength, this.yLength, T fill)
    : _list = List<T>.filled(xLength * yLength, fill);

  T operator [](XY xy) {
    checkState(withinBounds(xy));
    return _list[xy.x + xy.y * xLength];
  }

  void operator []=(XY xy, T value) {
    checkState(withinBounds(xy));
    _list[xy.x + xy.y * xLength] = value;
  }

  bool withinBounds(XY xy) =>
      (0 <= xy.x && xy.x < xLength) && (0 <= xy.y && xy.y < yLength);

  final int xLength;
  final int yLength;

  final List<T> _list;
}

///////////////////////////////////////////////////////////////////////////////
