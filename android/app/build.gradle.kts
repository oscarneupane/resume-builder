plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.applymate.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            // Populated via key.properties (see DEPLOY_ANDROID.md).
            // Falls back to debug signing if key.properties is absent.
            val props = java.util.Properties()
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) props.load(keyFile.inputStream())
            storeFile = if (props.getProperty("storeFile") != null) file(props.getProperty("storeFile")) else null
            storePassword = props.getProperty("storePassword") ?: ""
            keyAlias = props.getProperty("keyAlias") ?: ""
            keyPassword = props.getProperty("keyPassword") ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.applymate.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val props = java.util.Properties()
            val keyFile = rootProject.file("key.properties")
            signingConfig = if (keyFile.exists()) signingConfigs.getByName("releas