class MemberDetails {
  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final String bio;
  final bool isTokoUser;
  final DateTime? birthDate; // 📌 AÑADIDO: Fecha de Nacimiento

  MemberDetails({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    required this.bio,
    required this.isTokoUser,
    this.birthDate, // 📌 AÑADIDO AL CONSTRUCTOR
  });
}
