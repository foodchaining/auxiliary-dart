
[![Pub Version](https://img.shields.io/pub/v/auxiliary)](https://pub.dev/packages/auxiliary)
[![Pub Publisher](https://img.shields.io/pub/publisher/auxiliary)](https://pub.dev/packages/auxiliary/publisher)

An auxiliary Dart library.

It provides an assortment of useful general-purpose classes, functions, constants, etc. Most of these are standalone utilities; some are organized and interconnected.

## Overview

### Collections

* The [`EquatableList`][EquatableList], [`EquatableMap`][EquatableMap], and
  [`EquatableSet`][EquatableSet] classes are unmodifiable collections with deep
  equality.

* The [`LateList`][LateList] class is an unmodifiable `DelegatingList` that uses
  an `Iterable` as its source but iterates over it only once and only upon the
  first access to any element.

* The [`SortedMap`][SortedMap] class is a `TreeSet`-based `Map`. The ordering of
  keys is defined by a given `comparator` or by the default
  `Comparable.compareTo` function.

* The [`IMultimap`][IMultimap] class is an `IMap`-based immutable associative
  container that maps a key to multiple values.

* The [`Array2D`][Array2D] class is a two-dimensional array of objects.

### Error handling

* The [`gated`][gated], [`gatedAsync`][gatedAsync], [`later`][later], and
  [`alone`][alone] functions, along with the
  [`globalGateClosed`][globalGateClosed] property, help to prevent critical code
  sections (for example, data outputting code) from running in the case of a
  fatal program failure.

* The [`RuntimeError`][RuntimeError] and [`RuntimeException`][RuntimeException]
  classes may be used as bases for custom errors and exceptions. Both classes
  are derived from the [`RuntimeThrowable`][RuntimeThrowable] mixin.

* The [`WrappingError`][WrappingError] and
  [`WrappingException`][WrappingException] classes may be used when a thrown
  `Object` and its corresponding `StackTrace` must be handled as a single
  entity.

### Miscellaneous

* The [`log`][log] property provides convenient access to the logging
  functionality for libraries and applications.

* The [`ActorBase`][ActorBase] mixin is a model for a possible lifecycle of an
  `Object` instance. The [`Actor`][Actor] and [`ActorAsync`][ActorAsync] mixins
  supplement `ActorBase` with initialization and deactivation routines for
  synchronous and asynchronous scenarios.

* The [`StateMachine`][StateMachine] class is a `Stream`-based Finite State
  Machine implementation.

* See the package documentation for the full API.
