/// A user-editable parameter of an instrument template.
class ParamSpec {
  final String name;
  final double min;
  final double max;
  final double def;
  const ParamSpec(this.name, this.min, this.max, this.def);
}

const _env = [
  ParamSpec('attack', 0.001, 2, 0.01),
  ParamSpec('decay', 0.01, 2, 0.2),
  ParamSpec('sustain', 0, 1, 0.6),
  ParamSpec('release', 0.01, 3, 0.2),
];

enum Template {
  subtractive([
    ParamSpec('wave', 0, 1, 0),
    ParamSpec('cutoff', 100, 12000, 3000),
    ParamSpec('res', 0, 0.9, 0.2),
    ..._env,
  ]),
  fm([
    ParamSpec('ratio', 0.5, 8, 2),
    ParamSpec('index', 0, 10, 3),
    ..._env,
  ]),
  sampler([
    ParamSpec('pitch', 0.25, 4, 1),
    ParamSpec('attack', 0.001, 1, 0.001),
    ParamSpec('release', 0.01, 2, 0.1),
  ]),
  noise([
    ParamSpec('cutoff', 100, 12000, 4000),
    ParamSpec('decay', 0.01, 2, 0.15),
  ]);

  final List<ParamSpec> specs;
  const Template(this.specs);

  ParamSpec spec(String name) => specs.firstWhere((s) => s.name == name);
}

/// One of the 16 instrument slots.
class Instrument {
  final int id;
  final String name;
  final Template template;
  final Map<String, double> params;

  const Instrument({
    required this.id,
    required this.name,
    required this.template,
    required this.params,
  });

  static Instrument defaultFor(int id, Template template) => Instrument(
        id: id,
        name: template.name,
        template: template,
        params: {for (final s in template.specs) s.name: s.def},
      );

  Instrument copyWith({String? name, Template? template, Map<String, double>? params}) =>
      Instrument(
        id: id,
        name: name ?? this.name,
        template: template ?? this.template,
        params: params ?? this.params,
      );

  Instrument withParam(String name, double value) =>
      copyWith(params: {...params, name: value});
}
