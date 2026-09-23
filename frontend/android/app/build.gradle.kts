import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing material never lives in the repository. `android/key.properties`
// points at the keystore and carries its passwords; see
// `android/key.properties.example` and the release runbook in
// docs/OPERATIONS.md.
val signing = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val canSignReleases = signing.getProperty("storeFile") != null

// Signing a release with the debug key is worse than not building at all: the
// APK installs, so nobody notices, and no later release signed with the real
// key can ever replace it on a phone. A developer who only wants to run a
// release build locally passes -PallowDebugSigning.
val debugSigningAllowed = project.hasProperty("allowDebugSigning")

gradle.taskGraph.whenReady {
    val releasing = allTasks.any { it.name.contains("Release") }
    if (releasing && !canSignReleases && !debugSigningAllowed) {
        throw GradleException(
            "No android/key.properties, so this release would be signed with the " +
                "debug key and could never be updated. Copy key.properties.example " +
                "and fill it in, or pass -PallowDebugSigning for a local build."
        )
    }
}

android {
    namespace = "ph.kitaza.kitaza_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ph.kitaza.kitaza_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Both come from `version:` in pubspec.yaml, so one line governs what
        // a release is called and whether a phone treats it as newer.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (canSignReleases) {
            create("release") {
                storeFile = rootProject.file(signing.getProperty("storeFile"))
                storePassword = signing.getProperty("storePassword")
                keyAlias = signing.getProperty("keyAlias")
                keyPassword = signing.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (canSignReleases) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Dart code is already tree-shaken in a release build. R8 over the
            // Java side as well would save a little more, but it can only be
            // trusted once it has been run on a real phone against the camera
            // and printer plugins, so it stays off until the field trial.
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
