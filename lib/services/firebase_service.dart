import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/measurement_model.dart';
import '../models/comparison_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Projects
  Future<void> saveProject(ProjectModel project, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(project.id)
        .set(project.toFirestore());
  }

  Future<void> deleteProject(String userId, String projectId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  Stream<List<ProjectModel>> streamProjects(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc.data(), userId))
          .toList();
    });
  }

  // Measurements
  Future<void> saveMeasurement(
    String userId,
    String projectId,
    MeasurementModel measurement,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('measurements')
        .doc(measurement.id)
        .set(measurement.toFirestore());
  }

  Future<void> deleteMeasurement(
    String userId,
    String projectId,
    String measurementId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('measurements')
        .doc(measurementId)
        .delete();
  }

  Stream<List<MeasurementModel>> streamMeasurements(
    String userId,
    String projectId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('measurements')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeasurementModel.fromFirestore(doc.data(), projectId))
          .toList();
    });
  }

  // Comparisons
  Future<void> saveComparison(
    String userId,
    String projectId,
    ComparisonModel comparison,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('comparisons')
        .doc(comparison.id)
        .set(comparison.toFirestore());
  }

  Future<void> deleteComparison(
    String userId,
    String projectId,
    String comparisonId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('comparisons')
        .doc(comparisonId)
        .delete();
  }

  Stream<List<ComparisonModel>> streamComparisons(
    String userId,
    String projectId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('comparisons')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ComparisonModel.fromFirestore(doc.data(), projectId))
          .toList();
    });
  }
}
