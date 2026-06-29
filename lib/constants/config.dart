// Decibel thresholds
const double minDecibelValue = 0.0;
const double maxDecibelValue = 130.0;

// Status thresholds (dB)
const double safeThreshold = 70.0;      // Below 70dB is safe
const double warningThreshold = 85.0;   // 70-85dB is warning
// Above 85dB is danger

// Default calibration
const double defaultCalibration = 0.0;
const double calibrationStep = 1.0;
const double minCalibration = -10.0;
const double maxCalibration = 10.0;

// Audio service
const int audioSampleRate = 44100;
const int audioFrameSize = 4096;
const int dbUpdateIntervalMs = 100; // Update dB every 100ms

// Firebase
const String firebaseProjectId = 'measurebox-app';

// Hive boxes
const String hiveBoxUser = 'user';
const String hiveBoxProjects = 'projects';
const String hiveBoxMeasurements = 'measurements_';
const String hiveBoxComparisons = 'comparisons_';

// Chart
const int maxChartPoints = 100;
const double chartAnimationDuration = 300; // ms

// CSV export
const String csvFileName = 'MeasureBox_export.csv';
const String csvDateFormat = 'yyyy-MM-dd HH:mm:ss';
