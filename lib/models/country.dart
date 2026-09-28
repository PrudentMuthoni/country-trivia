class Country {
  final String name;
  final String isoCode;

  const Country({required this.name, required this.isoCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String,
      isoCode: json['alpha-2'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
