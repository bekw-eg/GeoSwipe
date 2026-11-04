class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.preferredLanguage = 'kk',
    required this.createdAt,
    this.geoBonusPoints = 0,
    this.unlockedBadges = const [],
  });

  final String id;
  final String email;
  final String username;
  final String displayName;
  final String preferredLanguage;
  final DateTime createdAt;
  final int geoBonusPoints;
  final List<String> unlockedBadges;

  AuthUser copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? preferredLanguage,
    DateTime? createdAt,
    int? geoBonusPoints,
    List<String>? unlockedBadges,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      geoBonusPoints: geoBonusPoints ?? this.geoBonusPoints,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'displayName': displayName,
    'preferredLanguage': preferredLanguage,
    'createdAt': createdAt.toIso8601String(),
    'geoBonusPoints': geoBonusPoints,
    'unlockedBadges': unlockedBadges,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id:
          json['id'] as String? ??
          'user_${DateTime.now().millisecondsSinceEpoch}',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName:
          json['displayName'] as String? ??
          (json['profile'] is Map
              ? (json['profile']['displayName'] as String? ?? '')
              : ''),
      preferredLanguage: json['preferredLanguage'] as String? ?? 'kk',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      geoBonusPoints: (json['geoBonusPoints'] as num?)?.toInt() ?? 0,
      unlockedBadges:
          (json['unlockedBadges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.savedAt,
  });

  final String token;
  final AuthUser user;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      user: AuthUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
