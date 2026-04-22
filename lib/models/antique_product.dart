class AntiqueProduct {
  const AntiqueProduct({
    required this.id,
    required this.productNumber,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.era,
    required this.material,
    required this.imageUrl,
    required this.story,
    required this.dimensions,
    required this.condition,
    this.isFeatured = false,
  });

  final String id;
  final String productNumber;
  final String name;
  final String description;
  final double price;
  final String category;
  final String era;
  final String material;
  final String imageUrl;
  final String story;
  final String dimensions;
  final String condition;
  final bool isFeatured;

  List<String> get tags => <String>[category, era, material];
}
