import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


// Read signing props from android/key.properties (or from env vars on CI)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("/key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
println(">>> key.props path = ${keystorePropertiesFile.absolutePath}, exists=${keystorePropertiesFile.exists()}")
println(">>> storeFile from props = ${keystoreProperties.getProperty("storeFile")}")



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
        require(!storeFilePath.isNullOrBlank()) { "Missing storeFile in android/key.properties" }
        storeFile = file(storeFilePath)

        keyAlias = (keystoreProperties["keyAlias"] as String?)
        require(!keyAlias.isNullOrBlank()) { "Missing keyAlias in android/key.properties" }

        storePassword = (keystoreProperties["storePassword"] as String?)
        require(!storePassword.isNullOrBlank()) { "Missing storePassword in android/key.properties" }

        keyPassword = (keystoreProperties["keyPassword"] as String?)
        require(!keyPassword.isNullOrBlank()) { "Missing keyPassword in android/key.properties" }
    }
}


buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
        isShrinkResources = false
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
