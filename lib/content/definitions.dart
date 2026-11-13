class BuildingDefinition {
 final String id,name,description; final Map<String,double> cost,yield; final int days; final String? technology;
 const BuildingDefinition(this.id,this.name,this.description,this.cost,this.yield,this.days,[this.technology]);
}
class Technology {
 final String id,name; final List<String> requires; final double cost; final String effect;
 const Technology(this.id,this.name,this.requires,this.cost,this.effect);
}
