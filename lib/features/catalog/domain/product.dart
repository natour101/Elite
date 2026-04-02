class Product {
  const Product({
    required this.id,
    required this.productNumber,
    required this.name,
    required this.segment,
    required this.category,
    required this.brand,
    required this.price,
    required this.image,
    required this.description,
    required this.sellerName,
    required this.sellerPhone,
    required this.stock,
    required this.isFeatured,
  });

  final String id;
  final String productNumber;
  final String name;
  final String segment;
  final String category;
  final String brand;
  final double price;
  final String image;
  final String description;
  final String sellerName;
  final String sellerPhone;
  final int stock;
  final bool isFeatured;

  bool get isAvailable => stock > 0;
}
