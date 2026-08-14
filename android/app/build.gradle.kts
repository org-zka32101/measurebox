import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing is optional and file-driven (standard Flutter pattern, see
// https://flutter.dev/to/reference-keystore): when android/key.properties
// exists (never committed — see android/.gitignore), the release build type
// signs with it below. Otherwise it falls back to the debug key, exactly as
// before, so `flutter build apk/appbundle --release` keeps working with no
// extra setup for local/CI verification builds.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yourwish.measuretrackers"
    // Tracks Flutter's own recommended value instead of a hardcoded number:
    // a pinned compileSdk (35) fell behind what the integration_test plugin
    // requires (36), which failed CI with "share_plus is currently compiled
    // against android-33" / AAR metadata check errors — plugins that don't
    // themselves specify a higher compileSdk fall back to whatever the app
    // module resolves, and an outdated pin here breaks that resolution.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yourwish.measuretrackers"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Signs with android/key.properties when present (real release
            // builds); falls back to the debug key otherwise (CI
            // verification builds, `flutter run --release`, etc.).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
