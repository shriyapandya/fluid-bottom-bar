import 'dart:math' as math;

/// A retargetable damped spring (unit mass) integrated manually so that the
/// target can change mid-flight without losing velocity.
class FluidSpring {
  /// Creates a spring resting at [value].
  FluidSpring(
    this.value, {
    required this.stiffness,
    required this.dampingRatio,
  }) : target = value;

  /// The current position.
  double value;

  /// The position the spring is pulled towards.
  double target;

  /// The current velocity, in units per second.
  double velocity = 0;

  /// Spring constant; higher is snappier.
  double stiffness;

  /// 1 is critically damped; lower values overshoot and wobble.
  double dampingRatio;

  static const double _restDelta = 0.0005;
  static const double _restVelocity = 0.0005;

  /// Whether the spring has settled on its target.
  bool get isAtRest =>
      (value - target).abs() < _restDelta && velocity.abs() < _restVelocity;

  /// Advances the simulation by [dt] seconds (semi-implicit Euler).
  void step(double dt) {
    final damping = 2 * dampingRatio * math.sqrt(stiffness);
    final force = -stiffness * (value - target) - damping * velocity;
    velocity += force * dt;
    value += velocity * dt;
  }

  /// Moves the spring onto its target and stops it.
  void snap() {
    value = target;
    velocity = 0;
  }

  /// Places the spring at rest at [v].
  void jumpTo(double v) {
    value = v;
    target = v;
    velocity = 0;
  }
}
