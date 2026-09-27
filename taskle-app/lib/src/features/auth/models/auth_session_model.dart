class AuthSessionModel {
  final bool hasSession;

  const AuthSessionModel({this.hasSession = false});

  AuthSessionModel copyWith({bool? hasSession}) =>
      AuthSessionModel(hasSession: hasSession ?? this.hasSession);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSessionModel && hasSession == other.hasSession;

  @override
  int get hashCode => hasSession.hashCode;
}
