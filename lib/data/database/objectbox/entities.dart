import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';

@Entity()
class MediaAnalysis {
  @Id()
  int id = 0;

  @Unique()
  String assetId;

  // نتائج ML Kit
  String? aiCaption;      // وصف تلقائي للصورة
  String? extractedText;  // نص OCR
  String? sentiment;      // 'positive' | 'negative' | 'neutral'
  double? credibilityScore;
  String? labelsJson;     // List<String> مخزنة كـ JSON string

  @HnswIndex(dimensions: 512, distanceType: VectorDistanceType.cosine)
  Float32List? embedding;

  DateTime analyzedAt;
  bool isAnalyzed;

  MediaAnalysis({
    this.id = 0,
    required this.assetId,
    this.aiCaption,
    this.extractedText,
    this.sentiment,
    this.credibilityScore,
    this.labelsJson,
    this.embedding,
    required this.analyzedAt,
    this.isAnalyzed = false,
  });
}
@Entity()
class PersonGroup {
  @Id()
  int id = 0;

  String groupId;
  String name;
  String? coverAssetId;
  DateTime createdAt;

  // علاقة one-to-many مع PersonAsset
  @Backlink('person')
  final assets = ToMany<PersonAsset>();

  PersonGroup({
    this.id = 0,
    required this.groupId,
    required this.name,
    this.coverAssetId,
    required this.createdAt,
  });
}
@Entity()
class PersonAsset {
  @Id()
  int id = 0;

  String assetId;

  // ToOne = many-to-one: صورة تنتمي لشخص واحد
  final person = ToOne<PersonGroup>();

  PersonAsset({
    this.id = 0,
    required this.assetId,
  });
}
@Entity()
class SecureFile {
  @Id()
  int id = 0;

  @Unique()
  String assetId;

  DateTime addedAt;

  SecureFile({
    this.id = 0,
    required this.assetId,
    required this.addedAt,
  });
}
@Entity()
class DuplicateGroup {
  @Id()
  int id = 0;

  String groupHash;
  DateTime foundAt;

  @Backlink('group')
  final members = ToMany<DuplicateMember>();

  DuplicateGroup({
    this.id = 0,
    required this.groupHash,
    required this.foundAt,
  });
}

@Entity()
class DuplicateMember {
  @Id()
  int id = 0;

  String assetId;
  String phash;
  int hammingDistance;

  final group = ToOne<DuplicateGroup>();

  DuplicateMember({
    this.id = 0,
    required this.assetId,
    required this.phash,
    required this.hammingDistance,
  });
}
