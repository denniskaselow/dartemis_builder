# dartemis_builder

A builder for dartemis to create the code necessary to initialize `Manager`s, `Mapper`s and `EntitySystem`s.

## Usage

Add the `@Generate` annotation on a `Manager` or `EntitySystem` and run `build_runner`.

```dart
@Generate(EntityProcessingSystem, allOf: [Velocity, Position])
class SimpleMovementSystem extends _$SimpleMovementSystem {
  @override
  void processEntity(Entity entity) {
    final velocity = velocityMapper[entity];
    positionMapper[entity]
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

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/denniskaselow/dartemis_builder/issues
