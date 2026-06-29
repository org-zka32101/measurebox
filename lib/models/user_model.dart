import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String email;

  @HiveField(2)
  String? displayName;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  double calibration;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.calibration = 0.0,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    double? calibration,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      calibration: calibration ?? this.calibration,
    );
  }
}
