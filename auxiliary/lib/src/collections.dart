// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "dart:collection";

import "package:dartz/dartz.dart";
import "package:equatable/equatable.dart";
import "package:meta/meta.dart";
import "package:quiver/check.dart";
import "package:quiver/collection.dart";

import "defs.dart";
import "exts.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A [List] of nullable [Object]s.
typedef StdList = List<Object?>;

/// A [Map] from nullable [Object]s to nullable [Object]s.
typedef StdMap = Map<Object?, Object?>;

/// A [Set] of nullable [Object]s.
typedef StdSet = Set<Object?>;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// An [EquatableList] of nullable [Object]s.
typedef EquatableStdList = EquatableList<Object?>;

/// An [EquatableMap] from nullable [Object]s to nullable [Object]s.
typedef EquatableStdMap = EquatableMap<Object?, Object?>;

/// An [EquatableSet] of nullable [Object]s.
typedef EquatableStdSet = EquatableSet<Object?>;

/// An [UnmodifiableListView] with deep equality.
@immutable
base class EquatableList<T extends Object?> extends UnmodifiableListView<T>
    with EquatableMixin, Stringified {
  ///
  /// Creates an equatable unmodifiable list view backed by [source].
  EquatableList(List<T> super.source) : props = source;

  @override
  final List<T> props;
}

/// An [UnmodifiableMapView] with deep equality.
@immutable
base class EquatableMap<K extends Object?, V extends Object?>
    extends UnmodifiableMapView<K, V>
    with EquatableMixin, Stringified {
  ///
  /// Creates an equatable unmodifiable map view backed by [source].
  EquatableMap(super.source) : props = [source];

  @override
  final List<Map<K, V>> props;
}

/// An [UnmodifiableSetView] with deep equality.
@immutable
base class EquatableSet<T extends Object?> extends UnmodifiableSetView<T>
    with EquatableMixin, Stringified {
  ///
  /// Creates an equatable unmodifiable set view backed by [source].
  EquatableSet(super.source) : props = [source];

  @override
  final List<Set<T>> props;
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// An unmodifiable [DelegatingList] with late delegate instantiation.
///
/// The implementation uses an [Iterable] as its source but iterates over it
/// only once and only upon the first read or write operation — either fully or
/// up to the specified length. The result of this iteration is used as the list
/// [delegate].
@immutable
base class LateList<T extends Object?> extends DelegatingList<T> {
  ///
  /// Creates an unmodifiable list that delegates to [iterable].
  ///
  /// The actual iteration over [iterable] happens only once and is postponed
  /// until the first list access.
  ///
  /// * If [length] is `-1`, all elements of [iterable] are iterated, and the
  ///   delegating list will have the same number of elements as [iterable].
  /// * If [length] is greater than `-1`, [iterable] must have at least [length]
  ///   elements. In this case, only the first [length] elements of [iterable]
  ///   are iterated, and the delegating list will have [length] elements.
  LateList(Iterable<T> iterable, {int length = -1})
    : _iterable = iterable,
      _length = length;

  /// A list to which this [LateList] delegates.
  ///
  /// It is created from the [Iterable] specified in [LateList.new] when this
  /// [LateList] is accessed for the first time.
  @override
  late final List<T> delegate = UnmodifiableListView(
    _iterable.xToList(length: _length),
  );

  final Iterable<T> _iterable;
  final int _length;
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A key–value pair representing an entry in a [SortedMap].
///
/// The [value] property of this object can be changed directly. This is the
/// most efficient way to associate a new value with [key] in a [SortedMap].
final class SortedMapEntry<K extends Ordered, V extends Object?> {
  ///
  /// Creates an entry with the given [key] and [value].
  SortedMapEntry(this.key, this.value);

  SortedMapEntry._key(this.key);

  /// The key of this entry.
  final K key;

  /// The value associated with [key] in a [SortedMap].
  ///
  /// It can be changed directly, which is the most efficient way to associate a
  /// new value with [key] in a [SortedMap].
  late V value;
}

/// A [Map] of key–value pairs stored as sorted entries.
///
/// The implementation of the [SortedMap] class is based on [TreeSet]. The map's
/// keys are compared using a [Comparator] function provided in the constructor.
/// If the [Comparator] is omitted, the keys are compared using the
/// [Comparable.compareTo] method.
///
/// An example of typical usage:
/// ```dart
/// var weekDays = SortedMap<int, String>();
/// weekDays.insert(7, "diēs Sāturnī");
/// weekDays.insert(1, "diēs Sōlis");
/// print(weekDays.map((var e) => "${e.key} => ${e.value}"));
/// // (1 => diēs Sōlis, 7 => diēs Sāturnī)
/// weekDays[1]!.value = "duminică";
/// weekDays.erase(7);
/// weekDays.insert(7, "sâmbătă");
/// print(weekDays.map((var e) => "${e.key} => ${e.value}"));
/// // (1 => duminică, 7 => sâmbătă)
/// ```
base class SortedMap<K extends Ordered, V extends Object?>
    extends IterableBase<SortedMapEntry<K, V>>
    with SetMixin<SortedMapEntry<K, V>> {
  ///
  /// Creates an empty [SortedMap].
  ///
  /// The ordering of the map entries is defined by [comparator] or by the
  /// default [Comparable.compareTo] function, i.e. `(K a, K b) =>
  /// a.compareTo(b)`.
  SortedMap({Comparator<K>? comparator})
    : _treeSet = TreeSet<SortedMapEntry<K, V>>(
        comparator: comparator != null
            ? (var a, var b) => comparator(a.key, b.key)
            : (var a, var b) => compare1<K>(a.key, b.key),
      );

  /// Uses [key] to locate an entry in this map.
  ///
  /// Returns `null` if [key] is not found in the map.
  SortedMapEntry<K, V>? operator [](K key) =>
      lookup(SortedMapEntry<K, V>._key(key));

  /// Adds a key–value pair as an entry to this map.
  ///
  /// Returns `true` if [key] was not yet present in the map; otherwise, returns
  /// `false` and the map is unchanged.
  bool insert(K key, V value) => add(SortedMapEntry<K, V>(key, value));

  /// Uses [key] to remove an entry from this map.
  ///
  /// Returns `false` if [key] is not found in the map.
  bool erase(K key) => remove(SortedMapEntry<K, V>._key(key));

  /// Adds [entry] to this map.
  ///
  /// Returns `true` if [entry]'s key was not yet present in the map; otherwise,
  /// returns `false` and leaves the map unchanged.
  @override
  bool add(SortedMapEntry<K, V> entry) => _treeSet.add(entry);

  /// Removes all entries from this map.
  @override
  void clear() => _treeSet.clear();

  /// Whether [element] is a [SortedMapEntry] pair contained in this map.
  @override
  bool contains(Object? element) {
    SortedMapEntry<K, V>? found = lookup(element);
    return found != null &&
        found.value == (element! as SortedMapEntry<K, V>).value;
  }

  /// If [element] is a [SortedMapEntry], its key is used to find an entry in
  /// this map.
  ///
  /// Returns `null` if [element] is not a [SortedMapEntry] or if its key is not
  /// found in the map.
  @override
  SortedMapEntry<K, V>? lookup(Object? element) => _treeSet.lookup(element);

  /// If [element] is a [SortedMapEntry], its key is used to remove an entry
  /// from this map.
  ///
  /// Returns `false` if [element] is not a [SortedMapEntry] or if its key was
  /// not found in the map.
  @override
  bool remove(Object? element) => _treeSet.remove(element);

  /// Returns a [TreeIterator] for the map entries, starting at the [anchor]
  /// key.
  ///
  /// By default, the returned iterator includes [anchor] on the first movement;
  /// if [inclusive] is set to `false`, [anchor] is excluded. The behavior of
  /// [TreeIterator.moveNext] and [TreeIterator.movePrevious] is reversed when
  /// [reversed] is set to `true`.
  TreeIterator<SortedMapEntry<K, V>> fromIterator(
    K anchor, {
    bool reversed = false,
    bool inclusive = true,
  }) => _treeSet.fromIterator(
    SortedMapEntry<K, V>._key(anchor),
    reversed: reversed,
    inclusive: inclusive,
  );

  /// A [TreeIterator] that iterates over the entries of this map.
  @override
  TreeIterator<SortedMapEntry<K, V>> get iterator => _treeSet.iterator;

  /// The last entry in this map.
  @override
  SortedMapEntry<K, V> get last => _treeSet.last;

  /// The number of entries in this map.
  @override
  int get length => _treeSet.length;

  final TreeSet<SortedMapEntry<K, V>> _treeSet;
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// An immutable associative container that maps a key to multiple values.
///
/// The implementation of the [IMultimap] class is based on [IMap]. A key lookup
/// returns an [IList] whose values are reversed relative to the order of their
/// insertion. The class's [operator ==] and [hashCode] are implemented using
/// the [EquatableMixin] mixin.
@immutable
base class IMultimap<K extends Object, V extends Object?>
    with EquatableMixin, Stringified {
  ///
  /// Creates a new multimap backed by the [map] argument.
  IMultimap(IMap<K, IList<V>> map) : _map = map;

  /// Creates a new empty multimap that uses [order] for key ordering.
  IMultimap.empty(Order<K> order) : _map = IMap<K, IList<V>>.empty(order);

  /// Returns an [IList] of values for the given [key].
  ///
  /// An empty list is returned if [key] is not mapped.
  IList<V> getList(K key) => _map.get(key).getOrElse(() => Nil<V>());

  /// Adds an association from the given [key] to the given [value].
  IMultimap<K, V> insert(K key, V value) {
    var list = getList(key);
    list = list.prependElement(value);
    return IMultimap(_map.put(key, list));
  }

  /// Removes the association between the given [key] and the given [value].
  ///
  /// The association must exist in the multimap before calling this method;
  /// otherwise, an [Error] is thrown.
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

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

/// A pair of integers that serve as coordinates for the [Array2D] class.
typedef XY = ({int x, int y});

/// A two-dimensional array of objects.
///
/// A single [Array2D] instance uses one [List] to store its elements. An
/// [Array2D] element is accessed using an [XY] pair of `x` and `y` coordinates,
/// which are always bounds-checked.
base class Array2D<T extends Object?> {
  ///
  /// Creates a new two-dimensional array filled with the [fill] value.
  ///
  /// The array uses `[0, xLength)` for the valid range of its `x` coordinates
  /// and `[0, yLength)` for the valid range of its `y` coordinates.
  Array2D(this.xLength, this.yLength, T fill)
    : _list = List<T>.filled(xLength * yLength, fill);

  /// Returns the object at the given [xy] coordinates in the array.
  ///
  /// The coordinates must be within the bounds of this array; [xy]'s `x` must
  /// be non-negative and less than [xLength], and [xy]'s `y` must be
  /// non-negative and less than [yLength].
  T operator [](XY xy) {
    checkState(withinBounds(xy));
    return _list[xy.x + xy.y * xLength];
  }

  /// Sets the object at the given [xy] coordinates in the array to [value].
  ///
  /// The coordinates must be within the bounds of this array; [xy]'s `x` must
  /// be non-negative and less than [xLength], and [xy]'s `y` must be
  /// non-negative and less than [yLength].
  void operator []=(XY xy, T value) {
    checkState(withinBounds(xy));
    _list[xy.x + xy.y * xLength] = value;
  }

  /// Whether the given [xy] coordinates are within the bounds of this array.
  bool withinBounds(XY xy) =>
      (0 <= xy.x && xy.x < xLength) && (0 <= xy.y && xy.y < yLength);

  /// Defines the valid range for the array's `x` coordinates as `[0, xLength)`.
  final int xLength;

  /// Defines the valid range for the array's `y` coordinates as `[0, yLength)`.
  final int yLength;

  final List<T> _list;
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
