plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
import java.io.FileInputStream
import java.util.Properties

// Read signing props from android/key.properties (or from env vars on CI)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("android/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mahaseel.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.mahaseel.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders += mapOf(
            "MAPS_API_KEY" to (System.getenv("MAPS_API_KEY") ?: "AIzaSyAegFmQ5xQqRKegRohcTUSsFj8a8u2WX1o")
        )
    }

    // ---- signing (release) ----
    signingConfigs {
        create("release") {
            val storeFilePath = (keystoreProperties["storeFile"] as String?)
                ?: System.getenv("STORE_FILE")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            keyAlias = (keystoreProperties["keyAlias"] as String?)
                ?: System.getenv("KEY_ALIAS")
            keyPassword = (keystoreProperties["keyPassword"] as String?)
                ?: System.getenv("KEY_PASSWORD")
            storePassword = (keystoreProperties["storePassword"] as String?)
                ?: System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        getByName("release") {
            // use the real release keystore (no more debug signing)
            signingConfig = signingConfigs.getByName("release")

            // shrink/obfuscate
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
