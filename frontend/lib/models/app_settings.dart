class AppSettings {
  final bool soundEffect;
  final bool animation;
  final bool listeningExercise;
  final bool parentalControl;
  final int timespentMinutes; // waktu belajar hari ini (dihitung server)
  final int timeLimitMinutes; // 0 = tanpa batas
  final String curfew; // format "HH:mm"
  final bool hasParentPin; // PIN orang tua sudah dibuat

  const AppSettings({
    this.soundEffect = true,
    this.animation = true,
    this.listeningExercise = true,
    this.parentalControl = false,
    this.timespentMinutes = 0,
    this.timeLimitMinutes = 60,
    this.curfew = '20:00',
    this.hasParentPin = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEffect: (j['soundEffect'] as bool?) ?? true,
        animation: (j['animation'] as bool?) ?? true,
        listeningExercise: (j['listeningExercise'] as bool?) ?? true,
        parentalControl: (j['parentalControl'] as bool?) ?? false,
        timespentMinutes: (j['timespentMinutes'] as int?) ?? 0,
        timeLimitMinutes: (j['timeLimitMinutes'] as int?) ?? 60,
        curfew: (j['curfew'] as String?) ?? '20:00',
        hasParentPin: (j['hasParentPin'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'soundEffect': soundEffect,
        'animation': animation,
        'listeningExercise': listeningExercise,
        'parentalControl': parentalControl,
        'timespentMinutes': timespentMinutes,
        'timeLimitMinutes': timeLimitMinutes,
        'curfew': curfew,
        'hasParentPin': hasParentPin,
      };

  AppSettings copyWith({
    bool? soundEffect,
    bool? animation,
    bool? listeningExercise,
    bool? parentalControl,
    int? timespentMinutes,
    int? timeLimitMinutes,
    String? curfew,
    bool? hasParentPin,
  }) {
    return AppSettings(
      soundEffect: soundEffect ?? this.soundEffect,
      animation: animation ?? this.animation,
      listeningExercise: listeningExercise ?? this.listeningExercise,
      parentalControl: parentalControl ?? this.parentalControl,
      timespentMinutes: timespentMinutes ?? this.timespentMinutes,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      curfew: curfew ?? this.curfew,
      hasParentPin: hasParentPin ?? this.hasParentPin,
    );
  }
}
