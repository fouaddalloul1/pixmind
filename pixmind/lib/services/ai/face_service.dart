import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  FaceService._();
  static final FaceService instance = FaceService._();

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: false,
      enableTracking: true,
      minFaceSize: 0.1,
    ),
  );

  Future<List<Face>> detectFaces(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _detector.processImage(inputImage);
    } catch (e) {
      return [];
    }
  }

  Future<int> countFaces(String imagePath) async {
    final faces = await detectFaces(imagePath);
    return faces.length;
  }

  void dispose() => _detector.close();
}
