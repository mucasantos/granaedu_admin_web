// Sub-model of Course

class CourseMeta {
  final String? duration, summary, description, language;
  final List? learnings, requirements;

  CourseMeta({
    this.duration,
    this.summary,
    this.description,
    this.learnings,
    this.requirements,
    this.language
  });

  factory CourseMeta.fromMap(Map<String, dynamic> meta) {
    final dynamic durationRaw = meta['duration'];
    final String? duration = durationRaw == null
        ? null
        : (durationRaw is String
            ? durationRaw
            : durationRaw.toString());

    final dynamic summaryRaw = meta['summary'];
    final String? summary = summaryRaw == null
        ? null
        : (summaryRaw is String ? summaryRaw : summaryRaw.toString());

    final dynamic descriptionRaw = meta['description'];
    final String? description = descriptionRaw == null
        ? null
        : (descriptionRaw is String ? descriptionRaw : descriptionRaw.toString());

    final dynamic languageRaw = meta['language'];
    final String? language = languageRaw == null
        ? null
        : (languageRaw is String ? languageRaw : languageRaw.toString());

    final List? learnings = meta['learnings'] is List ? meta['learnings'] as List : [];
    final List? requirements = meta['requirements'] is List ? meta['requirements'] as List : [];

    return CourseMeta(
      duration: duration,
      summary: summary,
      description: description,
      learnings: learnings,
      requirements: requirements,
      language: language,
    );
  }

  static Map<String, dynamic> getMap(CourseMeta d) {
    return {
      'duration': d.duration,
      'summary': d.summary,
      'description': d.description,
      'learnings': d.learnings,
      'requirements': d.requirements,
      'language': d.language
    };
  }
}
