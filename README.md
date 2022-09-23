# dartemis_builder
[![Build Status](https://github.com/denniskaselow/dartemis_builder/actions/workflows/dart.yml/badge.svg)](https://github.com/denniskaselow/dartemis_builder/actions/workflows/dart.yml)
[![Coverage Status](https://coveralls.io/repos/github/denniskaselow/dartemis_builder/badge.svg?branch=master)](https://coveralls.io/github/denniskaselow/dartemis_builder?branch=master)
[![Pub](https://img.shields.io/pub/v/dartemis_builder.svg)](https://pub.dartlang.org/packages/dartemis_builder)

A builder for dartemis to create the code necessary to initialize `Manager`s, `Mapper`s and `EntitySystem`s.

## Usage

Add `dartemis_builder` as a dev_dependency:

`dart pub add --dev dartemis_builder`

Add the `part` statement to your library and the `@Generate` annotation on a `Manager` or `EntitySystem` and run `build_runner`.

```dart
part 'filename.g.part';

@Generate(
  EntityProcessingSystem,
  allOf: [
    Position,
    Velocity,
  ],
)
class SimpleMovementSystem extends _$SimpleMovementSystem {
  @override
  void processEntity(int entity, Position position, Velocity velocity) {    
    position
      ..x += velocity.x * world.delta
      ..y += velocity.y * world.delta;
  }
}
```

A live template for systems and managers in WebStorm can be useful, for example:

```dart
@Generate($BASE_SYSTEM$)
class $CLASS_NAME$System extends _$$$CLASS_NAME$System {
}
```

And for the `part`-part:

```dart
part '$filename$.g.dart';
```  

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/denniskaselow/dartemis_builder/issues
