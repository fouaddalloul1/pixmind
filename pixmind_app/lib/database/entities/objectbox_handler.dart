// import '../database/entities/image_entity.dart';
// import '../objectbox.g.dart'; // هاد الملف رح يتولد تلقائياً لاحقاً
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// class ObjectBoxHandler {
//   late final Store store;
//   late final Box<ImageEntity> imageBox;

//   ObjectBoxHandler._create(this.store) {
//     imageBox = Box<ImageEntity>(store);
//   }

//   /// إعداد قاعدة البيانات وفتحها
//   static Future<ObjectBoxHandler> create() async {
//     final docsDir = await getApplicationDocumentsDirectory();
//     final store = await openStore(directory: p.join(docsDir.path, "pixmind-db"));
//     return ObjectBoxHandler._create(store);
//   }
// }