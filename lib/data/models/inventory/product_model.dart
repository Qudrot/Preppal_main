// lib/data/models/inventory/product_model.dart
//
// Represents a single inventory product.
// Combined Model + Entity approach (same as UserModel).

import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

// All available product categories (from Daily Sales Report screen)
enum ProductCategory {
  @JsonValue('Beverages') beverages,
  @JsonValue('Dairy') dairy,
  @JsonValue('Dish') dish,
  @JsonValue('Drink') drink,
  @JsonValue('Sauce') sauce,
  @JsonValue('Soup') soup,
  @JsonValue('Pasteries') pasteries,
  @JsonValue('Produce') produce,
  @JsonValue('Water') water,
  @JsonValue('Others') others,
}

// Units of measurement
enum ProductUnit {
  @JsonValue('kg') kg,
  @JsonValue('g') g,
  @JsonValue('L') litre,
  @JsonValue('ml') ml,
  @JsonValue('pcs') pcs,
  @JsonValue('dozen') dozen,
}

@JsonSerializable()
class ProductModel {
  // Custom decoder for production_date: if null or missing, default to Jan 1, 2020
  static DateTime _decodeProdDate(Object? raw) {
    if (raw == null) return DateTime(2020, 1, 1);
    if (raw is String) return DateTime.parse(raw);
    return DateTime(2020, 1, 1);
  }

  static double _decodeDouble(Object? raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  static double? _decodeDoubleOptional(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static int _decodeInt(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      // Handle cases where int might be sent as "12.0"
      return double.tryParse(raw)?.toInt() ?? 0;
    }
    return 0;
  }

  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: ProductCategory.others, unknownEnumValue: ProductCategory.others)
  final ProductCategory category;

  @JsonKey(name: 'productionDate', fromJson: _decodeProdDate)
  final DateTime productionDate;

  @JsonKey(name: 'shelf', fromJson: _decodeInt)
  final int shelfLife; // Backend uses 'shelf' for shelf-life hours

  int get shelfLifeDays => (shelfLife / 24).round();

  @JsonKey(name: 'quantityAvailable', fromJson: _decodeDouble)
  final double quantityAvailable;

  @JsonKey(fromJson: _decodeDouble)
  final double price;

  @JsonKey(fromJson: _decodeDouble)
  final double shelf; // Note: historically physical shelf, now often unused

  @JsonKey(defaultValue: ProductUnit.pcs, unknownEnumValue: ProductUnit.pcs)
  final ProductUnit unit;

  // user-selectable pricing currency for display only (NGN, USD, etc).
  // not sent to API until backend supports it, but kept in model so UI can
  // round-trip the value.
  @JsonKey(defaultValue: 'NGN')
  final String currency;

  // Low stock threshold — user defined per product
  // If null, falls back to the global fixed threshold (10)
  @JsonKey(name: 'lowStockThreshold', fromJson: _decodeDoubleOptional)
  final double? lowStockThreshold;

  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.productionDate,
    required this.shelfLife,
    required this.quantityAvailable,
    required this.price,
    this.shelf = 0,
    required this.unit,
    this.currency = 'NGN',
    this.lowStockThreshold,
    this.isActive = true,
  });

  // --- Computed Properties (no JSON, derived from data) ---

  // Uses user-defined threshold if set, otherwise falls back to 10
  double get effectiveThreshold => lowStockThreshold ?? 10;

  bool get isLowStock => quantityAvailable <= effectiveThreshold;

  /// expiry date computed from productionDate + shelfLife hours
  DateTime get expiryDate => productionDate.add(Duration(hours: shelfLife));

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final hoursUntilExpiry = expiryDate.difference(DateTime.now()).inHours;
    // consider "soon" as within 3 days (72 hours)
    return hoursUntilExpiry <= 72 && hoursUntilExpiry >= 0;
  }

  // copyWith — creates a modified copy of this product
  // Used when updating a product (immutability pattern)
  ProductModel copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    DateTime? productionDate,
    int? shelfLife,
    double? quantityAvailable,
    double? price,
    double? shelf,
    ProductUnit? unit,
    String? currency,
    double? lowStockThreshold,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      productionDate: productionDate ?? this.productionDate,
      shelfLife: shelfLife ?? this.shelfLife,
      quantityAvailable:
          quantityAvailable ?? this.quantityAvailable,
      price: price ?? this.price,
      shelf: shelf ?? this.shelf,
      unit: unit ?? this.unit,
      currency: currency ?? this.currency,
      lowStockThreshold:
          lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ProductModelToJson(this);

  /// Convert model into the shape expected by the backend inventory API
  /// (this drops fields that the server doesn’t recognise and adds the
  /// current businessId later in the datasource).
  Map<String, dynamic> toApiJson() {
    // Only include the fields expected by the backend. Do NOT send
    // extra keys (category, unit, currency, etc) or the request will
    // be rejected with a validation error.
    // Historically `shelf` represented the physical shelf location, but
    // recent backend changes now use the same field to carry the product’s
    // shelf-life value (hours). The server validates that this number is
    // non-negative, which is why previous clients saw 400s when the field
    // was omitted and defaulted to -1 on the server side.
    return {
      'productName': name,
      'quantityAvailable': quantityAvailable,
      'price': price,
      // use shelfLife here (should be >=0).
      'shelf': shelfLife < 0 ? 0 : shelfLife,
      // backend expects date-only string (YYYY-MM-DD)
      'productionDate': productionDate.toIso8601String().split('T').first,
    };
  }
}
