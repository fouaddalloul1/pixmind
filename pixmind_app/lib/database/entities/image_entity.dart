// import 'package:objectbox/objectbox.dart';

// @Entity()
// class ImageEntity {
//   @Id()
//   int id = 0; // معرف تلقائي لـ ObjectBox

//   @Index()
//   String path; // مسار الصورة الأصلي في الجهاز

//   String? fileName;
//   int sizeBytes;
//   DateTime dateAdded;

//   // الوسوم الناتجة عن YOLO (مثلاً: "سيارة", "شخص")
//   List<String> tags;

//   // النص المستخرج بواسطة OCR
//   String? ocrText;

//   // بصمة CLIP للبحث الدلالي (512 رقم)
//   // ملاحظة: نستخدم HnswIndex لتمويل البحث السريع في المتجهات
//   @HnswIndex(dimensions: 512)
//   List<double>? clipVector;

//   // إذا أردت تخزين الوجوه كعلاقة (To-Many) مستقبلاً
//   // final faces = ToMany<FaceEntity>(); 

//   ImageEntity({
//     required this.path,
//     this.fileName,
//     required this.sizeBytes,
//     required this.dateAdded,
//     this.tags = const [],
//     this.ocrText,
//     this.clipVector,
//   });
// }