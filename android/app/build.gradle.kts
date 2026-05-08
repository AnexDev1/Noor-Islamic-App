import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.anexon.noor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.anexon.noor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Use version info from pubspec.yaml via Flutter-generated local.properties
        versionCode = (project.findProperty("flutter.versionCode") as String?)?.toIntOrNull() ?: 2
        versionName = project.findProperty("flutter.versionName") as String? ?: "1.1.0"
    }

    // Create a signing config named "release" and load credentials from a properties file
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("keystore.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config loaded above. If keystore.properties is missing,
            // the release signing config will be empty and the build will fall back to debug signing.
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ── Home-screen widget dependencies ──
    // Prayer-time calculation (Adhan)
    implementation("com.batoulapps.adhan:adhan:1.2.1")
    // Hijri / Umm al-Qura calendar
    implementation("com.github.msarhan:ummalqura-calendar:2.0.2")
    // WorkManager for periodic widget refresh
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    // Kotlin coroutines (needed by WorkManager-ktx)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    // AppCompat for XML-based widgets
    implementation("androidx.appcompat:appcompat:1.7.0")
}

flutter {
    source = "../.."
}
