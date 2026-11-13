class BuildingDefinition {
  final String id, name, description;
  final Map<String, double> cost, yield;
  final Map<String, double> dailyInputs;
  final int days;
  final String? technology;
  final int housingCapacity, defense;
  const BuildingDefinition(
    this.id,
    this.name,
    this.description,
    this.cost,
    this.yield,
    this.days, [
    this.technology,
    this.housingCapacity = 0,
    this.defense = 0,
    this.dailyInputs = const {},
  ]);
}

class Technology {
  final String id, name;
  final List<String> requires;
  final double cost;
  final String effect;
  final Set<String> capabilities;
  const Technology(
    this.id,
    this.name,
    this.requires,
    this.cost,
    this.effect, [
    this.capabilities = const {},
  ]);
}
