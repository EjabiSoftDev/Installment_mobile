class Brand {
  final int id;
  final String name;
  final String? logo; // relative path

  const Brand({required this.id, required this.name, this.logo});

  factory Brand.fromJson(Map<String, dynamic> j) =>
      Brand(id: j['Id'] ?? 0, name: j['Name'] ?? '', logo: j['Logo']);
}
