/// Defaults are empty states, never demonstration data.
dynamic offlineDefault(String endpoint) {
  if (endpoint == '/settings') {
    return <String, dynamic>{
      'themeMode': 'light',
      'biometricLockEnabled': false,
      'timeZone': 'America/Sao_Paulo'
    };
  }
  if (endpoint == '/notifications' ||
      endpoint.startsWith('/progress/history')) {
    return <dynamic>[];
  }
  if (endpoint == '/challenges') {
    return <String, dynamic>{
      'joined': false,
      'weeklyAnswered': 0,
      'history': <dynamic>[]
    };
  }
  if (endpoint == '/progress') {
    return <String, dynamic>{
      'streakDays': 0,
      'level': 1,
      'totalXp': 0,
      'xpToNextLevel': 200,
      'weeklyAccuracy': 0,
      'minutesStudiedToday': 0,
      'reviewedToday': 0,
      'weekProgress': List.filled(7, false)
    };
  }
  return null;
}

bool supportsOfflineMutation(String endpoint) => endpoint == '/settings';

dynamic mutateOfflineResource(Map<String, dynamic> state, String method,
    String endpoint, Map<String, dynamic> body, String localId) {
  if (endpoint != '/settings' || !['PUT', 'DELETE'].contains(method)) {
    throw StateError('Operação indisponível offline.');
  }
  if (body.containsKey('themeMode') &&
      !['light', 'dark', 'system'].contains(body['themeMode'])) {
    throw StateError('Tema inválido.');
  }
  final reads = state['reads'] as Map;
  final settings = Map<String, dynamic>.from(method == 'DELETE'
      ? offlineDefault(endpoint)
      : reads[endpoint] ?? offlineDefault(endpoint));
  if (method == 'PUT') settings.addAll(body);
  reads[endpoint] = settings;
  return settings;
}
