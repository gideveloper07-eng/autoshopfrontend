class DealershipModel {
  final String clientId;
  final String propertyCode;
  final String propertyName;
  final String propertyDb;

  DealershipModel({
    required this.clientId,
    required this.propertyCode,
    required this.propertyName,
    required this.propertyDb,
  });

  factory DealershipModel.fromJson(Map<String, dynamic> json) {
    return DealershipModel(
      clientId: json['unqid'] ?? '',
      propertyCode: json['propertycode'] ?? '',
      propertyName: json['propertyname'] ?? '',
      propertyDb: json['propertydb'] ?? '',
    );
  }
}
