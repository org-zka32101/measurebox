import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/measurement_model.dart';
import '../models/comparison_model.dart';
import '../constants/config.dart';

class HiveService {
  static Future<void> initBoxes() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProjectModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MeasurementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ComparisonModelAdapter());
    }

    // Open boxes
    await Hive.openBox<UserModel>(hiveBoxUser);
    await Hive.openBox<ProjectModel>(hiveBoxProjects);
  }

  static Box<UserModel> getUserBox() {
    return Hive.box<UserModel>(hiveBoxUser);
  }

  static Box<ProjectModel> getProjectsBox() {
    return Hive.box<ProjectModel>(hiveBoxProjects);
  }

  static Future<Box<MeasurementModel>> getMeasurementsBox(String projectId) async {
    final boxName = '$hiveBoxMeasurements$projectId';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<MeasurementModel>(boxName);
    }
    return await Hive.openBox<MeasurementModel>(boxName);
  }

  static Future<Box<ComparisonModel>> getComparisonsBox(String projectId) async {
    final boxName = '$hiveBoxComparisons$projectId';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ComparisonModel>(boxName);
    }
    return await Hive.openBox<ComparisonModel>(boxName);
  }

  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  static Future<void> clearAllBoxes() async {
    await getUserBox().clear();
    await getProjectsBox().clear();
  }
}
