// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "package:meta/meta.dart";
import "package:quiver/check.dart";

import "errors.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

enum _ActorState { unset, active, deactivated }

/// Thrown when an [ActorBase] is expected to be in the `Active` state, but it
/// is not.
@immutable
base class InactiveActorException extends RuntimeException {
  @override
  Object get kind => "$InactiveActorException";
}

/// A model for a possible lifecycle of an [Object] instance.
///
/// Internally, the mixin maintains three states: `Uninitialized`, `Active`, and
/// `Deactivated`. Transitions are unidirectional in this order:
///
/// 1. `Uninitialized`: the initial state when an object is created.
/// 2. `Active`: the working state; it can be set by the [setActive] method when
///    the object is being initialized or is ready for use.
/// 3. `Deactivated`: the final state; it can be set by the [setDeactivated]
///    method when the object is not expected to change further.
///
/// The following example demonstrates how the state of an [ActorBase] can be
/// used to guard against unnecessary incoming asynchronous data. When the
/// `Store` object is deactivated — for example, during store maintenance — its
/// `trackRecentlyLiked` method stops processing new data and no longer modifies
/// the `Store` object. After maintenance, a new `Store` instance can be
/// constructed and initialized, with its `trackRecentlyLiked` method ready to
/// process new data further.
///
/// ```dart
/// base class Store with ActorBase {
///   /* ... */
///   Future<void> trackRecentlyLiked(Stream<String> likedItems) async {
///     checkActive();
///     await for (var item in likedItems) {
///       if (!isActive()) //
///         break;
///       _recentlyLiked[item] = DateTime.timestamp();
///       if (!isActive()) //
///         break;
///     }
///   }
///
///   final _recentlyLiked = LruMap<String, DateTime>(maximumSize: 43);
/// }
/// ```
///
/// Initialization and deactivation routines are introduced in the [ActorBase]
/// subtypes, [Actor] and [ActorAsync].
base mixin ActorBase {
  ///
  /// Whether the state is set to `Uninitialized`.
  bool isUninitialized() => _state == _ActorState.unset;

  /// Whether the state is set to `Active`.
  bool isActive() => _state == _ActorState.active;

  /// Whether the state is set to `Deactivated`.
  bool isDeactivated() => _state == _ActorState.deactivated;

  /// Whether the state is set to either `Active` or `Deactivated`.
  bool isInitialized() => !isUninitialized();

  /// Whether the state is set to either `Uninitialized` or `Active`.
  bool isUndeactivated() => !isDeactivated();

  /// Throws an [Error] if the state is not set to `Uninitialized`.
  @protected
  void checkUninitialized() => checkState(isUninitialized());

  /// Throws an [Error] if the state is not set to `Active`.
  @protected
  void checkActive() => checkState(isActive());

  /// Throws an [Error] if the state is not set to `Deactivated`.
  @protected
  void checkDeactivated() => checkState(isDeactivated());

  /// Throws an [Error] if the state is not set to either `Active` or
  /// `Deactivated`.
  @protected
  void checkInitialized() => checkState(isInitialized());

  /// Throws an [Error] if the state is not set to either `Uninitialized` or
  /// `Active`.
  @protected
  void checkUndeactivated() => checkState(isUndeactivated());

  /// Throws an [InactiveActorException] if the state is no longer set to
  /// `Active`.
  @protected
  void raiseInactive() {
    checkInitialized();
    if (!isActive()) //
      throw InactiveActorException();
  }

  /// Sets the state to `Active`.
  @protected
  void setActive() {
    checkUninitialized();
    _state = _ActorState.active;
  }

  /// Sets the state to `Deactivated`.
  @protected
  void setDeactivated() {
    checkActive();
    _state = _ActorState.deactivated;
  }

  _ActorState _state = _ActorState.unset;
}

/// Synchronous initialization and deactivation routines for [ActorBase].
///
/// Actual object initialization and deactivation code should be placed,
/// respectively, in the overridden [propose] and [dispose] methods of an
/// [Actor] subtype. These two methods must not be called directly by users of
/// an object. A public interface for object initialization and deactivation is
/// exposed via the [initialize] and [deactivate] methods.
///
/// [ActorAsync] is the asynchronous variant of this type.
base mixin Actor on ActorBase {
  ///
  /// A public interface for object initialization.
  ///
  /// Sets the state to `Active`, calls [propose], and if it throws an
  /// [Exception], calls [deactivate].
  @pragma("vm:notify-debugger-on-exception")
  void initialize() {
    setActive();
    try {
      propose();
    } on Exception {
      deactivate();
      rethrow;
    }
  }

  /// A public interface for object deactivation.
  ///
  /// If the state is `Active`, the method calls [dispose] and sets the state to
  /// `Deactivated`.
  void deactivate() {
    if (isActive()) {
      dispose();
      setDeactivated();
    }
  }

  /// Called by [initialize]; should contain the actual object initialization
  /// code.
  ///
  /// The method is allowed to throw in the case of an error. If it throws an
  /// [Exception], the default [Actor] implementation will call [dispose]
  /// afterward to clean up even a partially initialized object.
  @protected
  @mustCallSuper
  void propose() {
    checkActive();
  }

  /// Called by [deactivate]; should contain the actual object deactivation
  /// code.
  ///
  /// If [propose] throws an [Exception], the default [Actor] implementation
  /// will call [dispose] to clean up even a partially initialized object.
  @protected
  @mustCallSuper
  void dispose() {
    checkActive();
  }
}

/// Asynchronous initialization and deactivation routines for [ActorBase].
///
/// Actual object initialization and deactivation code should be placed,
/// respectively, in the overridden [propose] and [dispose] methods of an
/// [ActorAsync] subtype. These two methods must not be called directly by users
/// of an object. A public interface for object initialization and deactivation
/// is exposed via the [initialize] and [deactivate] methods.
///
/// [Actor] is the synchronous variant of this type.
base mixin ActorAsync on ActorBase {
  ///
  /// A public interface for object initialization.
  ///
  /// Sets the state to `Active`, calls [propose], and if it throws an
  /// [Exception], calls [deactivate].
  @pragma("vm:notify-debugger-on-exception")
  Future<void> initialize() async {
    setActive();
    try {
      await propose();
    } on Exception {
      await deactivate();
      rethrow;
    }
  }

  /// A public interface for object deactivation.
  ///
  /// If the state is `Active`, the method calls [dispose] and sets the state to
  /// `Deactivated`.
  Future<void> deactivate() async {
    if (isActive()) {
      await dispose();
      setDeactivated();
    }
  }

  /// Called by [initialize]; should contain the actual object initialization
  /// code.
  ///
  /// The method is allowed to throw in the case of an error. If it throws an
  /// [Exception], the default [ActorAsync] implementation will call [dispose]
  /// afterward to clean up even a partially initialized object.
  @protected
  @mustCallSuper
  Future<void> propose() async {
    checkActive();
  }

  /// Called by [deactivate]; should contain the actual object deactivation
  /// code.
  ///
  /// If [propose] throws an [Exception], the default [ActorAsync]
  /// implementation will call [dispose] to clean up even a partially
  /// initialized object.
  @protected
  @mustCallSuper
  Future<void> dispose() async {
    checkActive();
  }
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
