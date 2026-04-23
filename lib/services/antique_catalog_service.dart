import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/antique_product.dart';

class AntiqueCatalogService {
  AntiqueCatalogService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  Stream<List<AntiqueProduct>> watchProducts() {
    return _collection.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map(
            (doc) => (
              product: _fromMap(doc.id, doc.data()),
              createdAt: _createdAtSortValue(doc.data()['createdAt']),
            ),
          )
          .where((entry) => entry.product != null)
          .toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final normalizedProducts =
          products.map((entry) => entry.product!).toList(growable: false);

      if (normalizedProducts.isEmpty) {
        return _fallbackProducts;
      }

      return normalizedProducts;
    }).handleError((_) => _fallbackProducts);
  }

  Future<void> saveProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String era,
    required String material,
    required String imageUrl,
    required String story,
    required String dimensions,
    required String condition,
    bool isFeatured = false,
  }) async {
    final doc = _collection.doc();
    await doc.set({
      'productNumber': 'ANT-${DateTime.now().millisecondsSinceEpoch}',
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'category': category.trim(),
      'era': era.trim(),
      'material': material.trim(),
      'imageUrl': imageUrl.trim(),
      'story': story.trim(),
      'dimensions': dimensions.trim(),
      'condition': condition.trim(),
      'isFeatured': isFeatured,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  AntiqueProduct? _fromMap(String id, Map<String, dynamic> map) {
    final productNumber = '${map['productNumber'] ?? id}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    final description = '${map['description'] ?? ''}'.trim();
    final category = '${map['category'] ?? ''}'.trim();
    final era = '${map['era'] ?? map['period'] ?? 'حقبة كلاسيكية'}'.trim();
    final material = '${map['material'] ?? 'مواد أصلية مختارة'}'.trim();
    final imageUrl = '${map['imageUrl'] ?? ''}'.trim();
    final story = '${map['story'] ?? description}'.trim();
    final dimensions = '${map['dimensions'] ?? 'تفاصيل الأبعاد متاحة عند الطلب'}'.trim();
    final condition = '${map['condition'] ?? 'حالة ممتازة بالنسبة لعمر القطعة'}'.trim();
    final priceValue = map['price'];
    final price = priceValue is num ? priceValue.toDouble() : double.tryParse('$priceValue');

    if (name.isEmpty || description.isEmpty || category.isEmpty || price == null) {
      return null;
    }

    return AntiqueProduct(
      id: id,
      productNumber: productNumber,
      name: name,
      description: description,
      price: price,
      category: category,
      era: era,
      material: material,
      imageUrl: imageUrl.isEmpty ? _fallbackProducts.first.imageUrl : imageUrl,
      story: story,
      dimensions: dimensions,
      condition: condition,
      isFeatured: map['isFeatured'] == true,
    );
  }

  int _createdAtSortValue(dynamic value) {
    if (value is Timestamp) {
      return value.microsecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.microsecondsSinceEpoch;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.microsecondsSinceEpoch ?? 0;
    }
    return 0;
  }
}

const _fallbackProducts = <AntiqueProduct>[
  AntiqueProduct(
    id: 'antique-gramophone',
    productNumber: 'ANT-1001',
    name: 'جرامافون نحاسي من مطلع القرن',
    description: 'قطعة صوتية فاخرة بقاعدة خشبية محفورة تعكس روح الصالونات القديمة.',
    price: 780,
    category: 'أجهزة كلاسيكية',
    era: '1900 - 1920',
    material: 'خشب جوز ونحاس',
    imageUrl:
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=900&q=80',
    story:
        'اختيرت هذه القطعة لتمثل حضور الأنتيكا العملي؛ فهي ليست مجرد ديكور بل شاهد على زمن الاستماع الاحتفالي.',
    dimensions: 'الارتفاع 62 سم - العرض 38 سم',
    condition: 'مجددة بعناية مع الحفاظ على الطابع الأصلي',
    isFeatured: true,
  ),
  AntiqueProduct(
    id: 'antique-clock',
    productNumber: 'ANT-1002',
    name: 'ساعة مكتب فرنسية مذهبة',
    description: 'ساعة نحاسية بلمسات ذهبية داكنة تناسب المكاتب والصالات الكلاسيكية.',
    price: 540,
    category: 'ساعات أثرية',
    era: '1880 - 1910',
    material: 'نحاس مطلي ومرمر',
    imageUrl:
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
    story:
        'صممت هذه الساعة لتكون مركز المشهد على الرف أو الكونسول، مع حضور بصري دافئ وغير صاخب.',
    dimensions: 'الارتفاع 41 سم - العرض 26 سم',
    condition: 'الحركة الداخلية سليمة والهيكل الخارجي محفوظ',
    isFeatured: true,
  ),
  AntiqueProduct(
    id: 'antique-mirror',
    productNumber: 'ANT-1003',
    name: 'مرآة قصر بإطار محفور يدويًا',
    description: 'مرآة زخرفية بإطار خشبي عتيق تمنح المكان عمقًا وأناقة تراثية.',
    price: 920,
    category: 'ديكور جداري',
    era: '1920 - 1940',
    material: 'خشب سنديان وزخارف يدوية',
    imageUrl:
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=900&q=80',
    story:
        'قطعة مناسبة للمداخل الفخمة والزوايا الكلاسيكية، وتنجح في رفع مستوى المكان بصريًا فورًا.',
    dimensions: 'الارتفاع 110 سم - العرض 72 سم',
    condition: 'إطار أصلي مع معالجة خفيفة للحفاظ على المتانة',
    isFeatured: true,
  ),
  AntiqueProduct(
    id: 'antique-lamp',
    productNumber: 'ANT-1004',
    name: 'مصباح قراءة برونزي بقبعة زجاجية',
    description: 'مصباح طاولة كلاسيكي يضيف إضاءة دافئة وملمسًا تاريخيًا للمساحة.',
    price: 360,
    category: 'إضاءة تراثية',
    era: '1930 - 1950',
    material: 'برونز وزجاج معتق',
    imageUrl:
        'https://images.unsplash.com/photo-1517705008128-361805f42e86?auto=format&fit=crop&w=900&q=80',
    story: 'يعطي إحساس غرفة القراءة القديمة، ويعمل كعنصر جمالي حتى عند إطفائه.',
    dimensions: 'الارتفاع 48 سم - القطر 22 سم',
    condition: 'ممتاز مع استبدال التوصيلات الداخلية فقط',
  ),
  AntiqueProduct(
    id: 'antique-chest',
    productNumber: 'ANT-1005',
    name: 'صندوق مجوهرات عثماني صغير',
    description: 'صندوق خشبي مطعّم يناسب العرض الراقي للمقتنيات الخاصة والهدايا.',
    price: 295,
    category: 'صناديق ومقتنيات',
    era: 'أواخر القرن التاسع عشر',
    material: 'خشب مطعّم بالنحاس',
    imageUrl:
        'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=900&q=80',
    story:
        'قطعة محببة لهواة التفاصيل الصغيرة؛ تحفظ المقتنيات وتضيف قيمة بصرية واضحة.',
    dimensions: 'الطول 28 سم - العرض 18 سم',
    condition: 'آثار استخدام خفيفة تزيد من أصالتها',
  ),
  AntiqueProduct(
    id: 'antique-vase',
    productNumber: 'ANT-1006',
    name: 'مزهرية خزفية مزخرفة يدويًا',
    description: 'مزهرية تراثية برسومات يدوية وألوان هادئة مستلهمة من القصور الأوروبية.',
    price: 430,
    category: 'خزف وفازات',
    era: '1910 - 1930',
    material: 'خزف يدوي',
    imageUrl:
        'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&w=900&q=80',
    story:
        'تصلح كقطعة مركزية على الطاولات الجانبية أو داخل مكتبة ذات طابع كلاسيكي.',
    dimensions: 'الارتفاع 36 سم',
    condition: 'حالة محفوظة مع لمعان أصلي متوازن',
  ),
];