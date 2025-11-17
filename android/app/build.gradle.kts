import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.cloud.pira"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "androiddebugkey"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "android"
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "keystore/debug.keystore")
            storePassword = keystoreProperties.getProperty("storePassword") ?: "android"
        }
    }

    defaultConfig {
        applicationId = "com.cloud.pira"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 53
        versionName = "3.8.3"

        manifestPlaceholders.put("io.flutter.embedding.android.EnableImpeller", "false")
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("x86_64", "armeabi-v7a", "arm64-v8a")
            isUniversalApk = true
        }
    }

    buildTypes {
        getByName("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: "keystore/debug.keystore"
            signingConfig = if (file(storeFilePath).exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                abiFilters.addAll(listOf("x86_64", "armeabi-v7a", "arm64-v8a"))
                debugSymbolLevel = "FULL"
            }
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                abiFilters.addAll(listOf("x86_64", "armeabi-v7a", "arm64-v8a"))
                debugSymbolLevel = "FULL"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}