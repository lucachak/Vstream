enum SubscriptionPlan {
  free,
  premium,
  vip;

  String get label => name.toUpperCase();
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final int avatarColorValue;
  final List<String> watchlistIds;
  final SubscriptionPlan plan;
  final DateTime? planExpiry;
  final DateTime? dob;
  final String? gender;
  final bool isAdultContentEnabled;
  final List<String> favoriteGenres;
  final bool pushNotificationsEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarColorValue = 0xFFE50914,
    this.watchlistIds = const [],
    this.plan = SubscriptionPlan.free,
    this.planExpiry,
    this.dob,
    this.gender,
    this.isAdultContentEnabled = false,
    this.favoriteGenres = const [],
    this.pushNotificationsEnabled = true,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    int? avatarColorValue,
    List<String>? watchlistIds,
    SubscriptionPlan? plan,
    DateTime? planExpiry,
    DateTime? dob,
    String? gender,
    bool? isAdultContentEnabled,
    List<String>? favoriteGenres,
    bool? pushNotificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      watchlistIds: watchlistIds ?? this.watchlistIds,
      plan: plan ?? this.plan,
      planExpiry: planExpiry ?? this.planExpiry,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      isAdultContentEnabled: isAdultContentEnabled ?? this.isAdultContentEnabled,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarColorValue': avatarColorValue,
        'watchlistIds': watchlistIds,
        'plan': plan.name,
        'planExpiry': planExpiry?.toIso8601String(),
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'isAdultContentEnabled': isAdultContentEnabled,
        'favoriteGenres': favoriteGenres,
        'pushNotificationsEnabled': pushNotificationsEnabled,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarColorValue: (json['avatarColorValue'] as int?) ?? 0xFFE50914,
      watchlistIds: ((json['watchlistIds'] as List?)?.cast<String>()) ?? [],
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      planExpiry: json['planExpiry'] != null
          ? DateTime.tryParse(json['planExpiry'] as String)
          : null,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'] as String) : null,
      gender: json['gender'] as String?,
      isAdultContentEnabled: json['isAdultContentEnabled'] as bool? ?? false,
      favoriteGenres: ((json['favoriteGenres'] as List?)?.cast<String>()) ?? [],
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
    );
  }
}
