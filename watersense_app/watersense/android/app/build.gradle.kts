plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.watersense"
    compileSdk = 34 // ✅ aumenta para 33 para corrigir o erro lStar
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.watersense"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // ✅ garante compatibilidade com Android 12+
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
