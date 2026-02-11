plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // keep Flutter plugin
    id("com.google.gms.google-services")    // ✅ Firebase plugin
}

android {
    namespace = "com.example.myoceanapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.myoceanapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // You can set up your own signing config here for release builds
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Enable core library desugaring for Java 17
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // ✅ Firebase BOM keeps versions aligned
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // ✅ Firebase Messaging for push notifications
    implementation("com.google.firebase:firebase-messaging")

    // (Optional) Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // ✅ Desugar JDK libs for notifications plugin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
