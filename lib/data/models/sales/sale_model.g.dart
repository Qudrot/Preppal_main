// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemModel _$SaleItemModelFromJson(Map<String, dynamic> json) =>
    SaleItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantitySold: SaleItemModel._decodeDouble(json['quantitySold']),
      unitPrice: SaleItemModel._decodeDouble(json['unitPrice']),
    );

Map<String, dynamic> _$SaleItemModelToJson(SaleItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantitySold': instance.quantitySold,
      'unitPrice': instance.unitPrice,
    };

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'items': instance.items,
  'notes': instance.notes,
};
