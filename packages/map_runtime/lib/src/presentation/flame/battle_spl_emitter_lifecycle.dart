final class BattleSplChildTiming {
  const BattleSplChildTiming({
    required this.emissionCount,
    required this.emissionDelay256,
    required this.emissionInterval,
    required this.lifetime,
  });

  final int emissionCount;
  final int emissionDelay256;
  final int emissionInterval;
  final int lifetime;
}

final class BattleSplEmitterStep {
  const BattleSplEmitterStep({
    required this.started,
    required this.complete,
    required this.emittedParents,
    required this.emittedChildren,
    required this.droppedParents,
    required this.droppedChildren,
    required this.activeParents,
    required this.activeChildren,
  });

  final bool started;
  final bool complete;
  final int emittedParents;
  final int emittedChildren;
  final int droppedParents;
  final int droppedChildren;
  final int activeParents;
  final int activeChildren;
}

final class BattleSplEmitterLifecycle {
  BattleSplEmitterLifecycle({
    required this.emitterLifetime,
    required this.emissionInterval,
    required this.emissionRate4096,
    required int particleLifetime,
    required this.particleLifetimeVariance,
    required this.maxParticles,
    this.startDelay = 0,
    this.updateCycle = 0,
    this.autoTerminate = true,
    this.child,
  }) : _particleLifetime = ((particleLifetime * 255) >> 8) + 1 {
    final childTiming = child;
    if (startDelay < 0 ||
        startDelay > 65535 ||
        emitterLifetime < 0 ||
        emitterLifetime > 65535 ||
        (autoTerminate && emitterLifetime == 65535) ||
        emissionInterval < 1 ||
        emissionInterval > 255 ||
        emissionRate4096 < 0 ||
        emissionRate4096 > 64 * 4096 ||
        particleLifetime < 1 ||
        particleLifetime > 65535 ||
        particleLifetimeVariance != 0 ||
        updateCycle < 0 ||
        updateCycle > 2 ||
        maxParticles < 1 ||
        maxParticles > 4096 ||
        (childTiming != null &&
            (childTiming.emissionCount < 1 ||
                childTiming.emissionCount > 64 ||
                childTiming.emissionDelay256 < 0 ||
                childTiming.emissionDelay256 > 255 ||
                childTiming.emissionInterval < 1 ||
                childTiming.emissionInterval > 255 ||
                childTiming.lifetime < 1 ||
                childTiming.lifetime > 65534 ||
                _particleLifetime < 2 ||
                _particleLifetime * childTiming.emissionDelay256 > 524287))) {
      throw const FormatException('Invalid SPL emitter timing');
    }
  }

  final int emitterLifetime;
  final int emissionInterval;
  final int emissionRate4096;
  final int particleLifetimeVariance;
  final int maxParticles;
  final int startDelay;
  final int updateCycle;
  final bool autoTerminate;
  final BattleSplChildTiming? child;
  final int _particleLifetime;

  List<_ParticleAge> _parents = [];
  List<_ParticleAge> _children = [];
  int _age = 0;
  int _emissionFraction = 0;
  bool _started = false;
  bool _terminate = false;
  bool _complete = false;

  BattleSplEmitterStep step({
    required int managerFrame,
    bool paused = false,
    bool stopEmission = false,
    bool terminate = false,
  }) {
    if (managerFrame < 0 || managerFrame > 1) {
      throw ArgumentError.value(managerFrame, 'managerFrame');
    }
    if (_complete) return _result();
    _terminate = _terminate || terminate;
    if (!_started && _age >= startDelay) {
      _started = true;
      _age = 0;
    }

    var emittedParents = 0;
    var emittedChildren = 0;
    var droppedParents = 0;
    var droppedChildren = 0;
    if (!paused && (updateCycle == 0 || managerFrame == updateCycle - 1)) {
      final parents = <_ParticleAge>[];
      if (_started &&
          !_terminate &&
          !stopEmission &&
          (emitterLifetime == 0 || _age < emitterLifetime) &&
          _age % emissionInterval == 0) {
        final emissions = emissionRate4096 + _emissionFraction;
        _emissionFraction = emissions & 4095;
        final requested = emissions >> 12;
        final available = maxParticles - _parents.length - _children.length;
        emittedParents = requested < available ? requested : available;
        droppedParents = requested - emittedParents;
        parents.addAll(List.generate(emittedParents, (_) => _ParticleAge()));
      }
      parents.addAll(_parents);

      var liveParents = parents.length;
      final survivingParents = <_ParticleAge>[];
      final newChildren = <_ParticleAge>[];
      final childTiming = child;
      for (final parent in parents) {
        if (childTiming != null) {
          final sinceDelay =
              parent.age * 256 -
              _particleLifetime * childTiming.emissionDelay256;
          if (sinceDelay >= 0 &&
              (sinceDelay ~/ 256) % childTiming.emissionInterval == 0) {
            final available =
                maxParticles -
                liveParents -
                _children.length -
                newChildren.length;
            final count = childTiming.emissionCount < available
                ? childTiming.emissionCount
                : available;
            emittedChildren += count;
            droppedChildren += childTiming.emissionCount - count;
            newChildren.addAll(List.generate(count, (_) => _ParticleAge()));
          }
        }
        parent.age++;
        if (parent.age > _particleLifetime) {
          liveParents--;
        } else {
          survivingParents.add(parent);
        }
      }
      _parents = survivingParents;

      if (childTiming != null) {
        final survivingChildren = <_ParticleAge>[];
        for (final particle in [...newChildren, ..._children]) {
          particle.age++;
          if (particle.age <= childTiming.lifetime) {
            survivingChildren.add(particle);
          }
        }
        _children = survivingChildren;
      }
      _age = (_age + 1) & 65535;
    }

    if ((_terminate ||
            (autoTerminate &&
                emitterLifetime != 0 &&
                _started &&
                _age > emitterLifetime)) &&
        _parents.isEmpty &&
        _children.isEmpty) {
      _complete = true;
    }
    return _result(
      emittedParents: emittedParents,
      emittedChildren: emittedChildren,
      droppedParents: droppedParents,
      droppedChildren: droppedChildren,
    );
  }

  BattleSplEmitterStep _result({
    int emittedParents = 0,
    int emittedChildren = 0,
    int droppedParents = 0,
    int droppedChildren = 0,
  }) => BattleSplEmitterStep(
    started: _started,
    complete: _complete,
    emittedParents: emittedParents,
    emittedChildren: emittedChildren,
    droppedParents: droppedParents,
    droppedChildren: droppedChildren,
    activeParents: _parents.length,
    activeChildren: _children.length,
  );
}

final class _ParticleAge {
  int age = 0;
}
