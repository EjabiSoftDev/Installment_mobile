class GroupName {
  final int id;
  final String nameAr;
  final String nameEn;

  const GroupName({required this.id, required this.nameAr, required this.nameEn});

  factory GroupName.fromJson(Map<String, dynamic> j) => GroupName(
        id: j['Id'] ?? 0,
        nameAr: (j['Name_ar'] ?? '').toString(),
        nameEn: (j['Name_eng'] ?? '').toString(),
      );
}
