import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sidhant.wallet"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sidhant.wallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only configure release signing when key.properties is present
            // (it is gitignored, so CI/debug builds skip this gracefully).
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
                // Fall back to the store password when keyPassword is absent
                // or blank — this matches the CI workflow's store=key fallback
                // and covers keystores that share one password for both entries.
                val kp = keystoreProperties["keyPassword"] as? String
                keyPassword = if (!kp.isNullOrEmpty()) kp else storePassword
                // Explicitly set the keystore type so AGP doesn't guess from
                // the .jks extension — the file may actually be PKCS#12.
                keystoreProperties["storeType"]?.let { storeType = it as String }
            }
        }
    }

    buildTypes {
        release {
            // When key.properties is present (CI injects it), sign with the
            // real release keystore. When absent (local dev without signing
            // keys), fall back to the debug signing config so that
            // `flutter build apk --release` still works locally.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Enable R8/ProGuard code shrinking & obfuscation for release
            // builds. This reduces APK size and enables dead-code elimination.
            //
            // proguardFiles:
            //   1. proguard-android-optimize.txt — AGP's default rules
            //      (shrinking + optimization, NOT the -dontoptimize variant).
            //   2. proguard-rules.pro — project-specific keep rules.
            //      Currently contains -dontwarn for ML Kit's Chinese/Japanese/
            //      Korean/Devanagari text recognizers that we don't bundle
            //      (we only use Latin script → saves ~25 MB APK size).
            //      WITHOUT these -dontwarn rules R8 fails with:
            //        Missing class com.google.mlkit.vision.text.chinese.*
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
            val abiName = output.getFilter(com.android.build.OutputFile.ABI)
            val abiCode = abiCodes[abiName]
            if (abiCode != null) {
                output.versionCodeOverride = (variant.versionCode) * 100 + abiCode
            }
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
    // BiometricPrompt with DEVICE_CREDENTIAL-only authenticator for PIN/password
    // verification (used by the "Delete all data" flow to force PIN, not fingerprint).
    implementation("androidx.biometric:biometric:1.1.0")

    // Google ML Kit Text Recognition (BUNDLED model — 100% offline, never
    // downloads / uploads). This model recognises digits + Latin script.
    // Used to read bank card numbers (卡号), expiry dates, CVV, and cardholder
    // name on-device. No INTERNET permission required.
    // Chinese model excluded: card fields are digits/Latin only, which saves
    // ~25 MB of APK size.
    implementation("com.google.mlkit:text-recognition:16.0.1")
}
