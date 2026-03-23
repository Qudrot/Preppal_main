// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  category:
      $enumDecodeNullable(
        _$ProductCategoryEnumMap,
        json['category'],
        unknownValue: ProductCategory.others,
      ) ??
      ProductCategory.others,
  productionDate: ProductModel._decodeProdDate(json['productionDate']),
  shelfLife: ProductModel._decodeInt(json['shelfLife']),
  quantityAvailable: ProductModel._decodeDouble(json['quantityAvailable']),
  price: ProductModel._decodeDouble(json['price']),
  shelf: json['shelf'] == null ? 0 : ProductModel._decodeDouble(json['shelf']),
  unit:
      $enumDecodeNullable(
        _$ProductUnitEnumMap,
        json['unit'],
        unknownValue: ProductUnit.pcs,
      ) ??
      ProductUnit.pcs,
  currency: json['currency'] as String? ?? 'NGN',
  lowStockThreshold: ProductModel._decodeDoubleOptional(
    json['lowStockThreshold'],
  ),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$ProductCategoryEnumMap[instance.category]!,
      'productionDate': instance.productionDate.toIso8601String(),
      'shelfLife': instance.shelfLife,
      'quantityAvailable': instance.quantityAvailable,
      'price': instance.price,
      'shelf': instance.shelf,
      'unit': _$ProductUnitEnumMap[instance.unit]!,
      'currency': instance.currency,
      'lowStockThreshold': instance.lowStockThreshold,
      'isActive': instance.isActive,
    };

const _$ProductCategoryEnumMap = {
  ProductCategory.beverages: 'Beverages',
  ProductCategory.dairy: 'Dairy',
  ProductCategory.dish: 'Dish',
  ProductCategory.drink: 'Drink',
  ProductCategory.sauce: 'Sauce',
  ProductCategory.soup: 'Soup',
  ProductCategory.pasteries: 'Pasteries',
  ProductCategory.produce: 'Produce',
  ProductCategory.water: 'Water',
  ProductCategory.others: 'Others',
};

const _$ProductUnitEnumMap = {
  ProductUnit.kg: 'kg',
  ProductUnit.g: 'g',
  ProductUnit.litre: 'L',
  ProductUnit.ml: 'ml',
  ProductUnit.pcs: 'pcs',
  ProductUnit.dozen: 'dozen',
};
