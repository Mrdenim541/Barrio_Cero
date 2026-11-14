import 'work_order.dart';

class CourseDefinition {
  final String id, name, role, description, manualTechnology;
  final Set<String> teacherRoles;
  const CourseDefinition(
    this.id,
    this.name,
    this.role,
    this.description,
    this.teacherRoles,
    this.manualTechnology,
  );
}

const courses = <CourseDefinition>[
  CourseDefinition(
    'craft',
    'Oficios de fabricación',
    'artesana',
    'Mejora el aprovechamiento de talla, trenzado y fabricación de herramientas.',
    {'artesana', 'artesano', 'técnica'},
    'engineering',
  ),
  CourseDefinition(
    'technical',
    'Oficios técnicos',
    'técnica',
    'Forma una persona capaz de conducir el estudio de instalaciones.',
    {'técnica'},
    'science',
  ),
  CourseDefinition(
    'scout',
    'Exploración',
    'explorador',
    'Un explorador formado reduce el trabajo necesario para una expedición.',
    {'explorador'},
    'logistics',
  ),
];

class LearningProject {
  final String id, learner, course, cause;
  final String? teacher;
  final int startingSkill;
  final WorkOrder work;
  LearningProject(
    this.id,
    this.learner,
    this.course,
    this.cause,
    this.work, {
    this.teacher,
    this.startingSkill = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'learner': learner,
    'course': course,
    'cause': cause,
    'teacher': teacher,
    'startingSkill': startingSkill,
    'work': work.toJson(),
  };
  factory LearningProject.fromJson(Map<String, dynamic> raw) {
    const keys = {
      'id',
      'learner',
      'course',
      'cause',
      'teacher',
      'startingSkill',
      'work',
    };
    if (raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        ['id', 'learner', 'course', 'cause'].any(
          (k) => raw[k] is! String || raw[k].isEmpty || raw[k].length > 128,
        ) ||
        raw['teacher'] != null &&
            (raw['teacher'] is! String ||
                raw['teacher'].isEmpty ||
                raw['teacher'].length > 128) ||
        raw['startingSkill'] is! int ||
        raw['startingSkill'] < 0 ||
        raw['startingSkill'] >= 1000 ||
        raw['work'] is! Map ||
        !courses.any((c) => c.id == raw['course'])) {
      throw const FormatException('Formación incompatible');
    }
    final work = WorkOrder.fromJson(Map<String, dynamic>.from(raw['work']));
    if (work.id != raw['id'] ||
        work.workers != (raw['teacher'] == null ? 1 : 2)) {
      throw const FormatException('Personal de formación incoherente');
    }
    return LearningProject(
      raw['id'],
      raw['learner'],
      raw['course'],
      raw['cause'],
      work,
      teacher: raw['teacher'],
      startingSkill: raw['startingSkill'],
    );
  }
}

class LearningQuote {
  final bool allowed;
  final String reason;
  final CourseDefinition? course;
  final String? teacher, learner, cohort;
  final int workers, totalWork;
  final Map<String, double> costs;
  const LearningQuote.rejected(this.reason)
    : allowed = false,
      course = null,
      teacher = null,
      learner = null,
      cohort = null,
      workers = 0,
      totalWork = 0,
      costs = const {};
  LearningQuote({
    required this.course,
    required this.teacher,
    required this.learner,
    required this.cohort,
    required this.workers,
    required this.totalWork,
    required Map<String, double> costs,
  }) : allowed = true,
       reason = 'Formación disponible.',
       costs = Map.unmodifiable(costs);
  int get days => workers == 0 ? 0 : (totalWork / workers).ceil();
}
