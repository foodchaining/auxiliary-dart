// Copyright: (C) 2025 foodchaining
// License: BSD 3-Clause "New" or "Revised" License

import "package:meta/meta.dart";
import "package:quiver/check.dart";

import "errors.dart";

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

enum _ActorState { unset, active, deactivated }

@immutable
base class InactiveActorException extends RuntimeException {
  @override
  Object get kind => "$InactiveActorException";
}

base mixin ActorBase {
  //
  bool isUninitialized() => _state == _ActorState.unset;
  bool isActive() => _state == _ActorState.active;
  bool isDeactivated() => _state == _ActorState.deactivated;

  bool isInitialized() => !isUninitialized();
  bool isUndeactivated() => !isDeactivated();

  @protected
  void checkUninitialized() => checkState(isUninitialized());

  @protected
  void checkActive() => checkState(isActive());

  @protected
  void checkDeactivated() => checkState(isDeactivated());

  @protected
  void checkInitialized() => checkState(isInitialized());

  @protected
  void checkUndeactivated() => checkState(isUndeactivated());

  @protected
  void raiseInactive() {
    checkInitialized();
    if (!isActive()) //
      throw InactiveActorException();
  }

  @protected
  void setActive() {
    checkUninitialized();
    _state = _ActorState.active;
  }

  @protected
  void setDeactivated() {
    checkActive();
    _state = _ActorState.deactivated;
  }

  _ActorState _state = _ActorState.unset;
}

base mixin Actor on ActorBase {
  //
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

  void deactivate() {
    if (isActive()) {
      dispose();
      setDeactivated();
    }
  }

  @protected
  @mustCallSuper
  void propose() {
    checkActive();
  }

  @protected
  @mustCallSuper
  void dispose() {
    checkActive();
  }
}

base mixin ActorAsync on ActorBase {
  //
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

  Future<void> deactivate() async {
    if (isActive()) {
      await dispose();
      setDeactivated();
    }
  }

  @protected
  @mustCallSuper
  Future<void> propose() async {
    checkActive();
  }

  @protected
  @mustCallSuper
  Future<void> dispose() async {
    checkActive();
  }
}

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
