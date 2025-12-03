plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.watersense"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.watersense"
        minSdk = flutter.minSdkVersion // ou flutter.minSdkVersion se usar o gradle Flutter DSL
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            keyAlias = "watersense_key"
            keyPassword = "378203"
            storeFile = file("release-key.jks")
            storePassword = "378203"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        disable.add("InvalidPackage")
        disable.add("ObsoleteLintCustomCheck")
    }
}

flutter {
    source = "../.."
}
