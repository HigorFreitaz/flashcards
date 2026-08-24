class AppUser {
  AppUser({required this.name, required this.email, required this.password});
  AppUser.login({required this.email, required this.password}) : name = '';

  String name;
  String email;
  String password;

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
