import org.gradle.api.GradleException
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
    compileSdk = flutter.compileSdkVersion
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
            // SAFE loading phase (no exceptions).
            // Read values only when key.properties exists; missing fields stay
            // null so that the actual release variant validation below can
            // surface them with a precise GradleException.
            // Debug builds (flutter run) never touch this signing config, so
            // local dev without any signing keys still works.
            if (keystorePropertiesFile.exists()) {
                val keyAliasProp = keystoreProperties["keyAlias"] as? String
                val storeFileProp = keystoreProperties["storeFile"] as? String
                val storePasswordProp = keystoreProperties["storePassword"] as? String
                val keyPasswordProp = keystoreProperties["keyPassword"] as? String
                val storeTypeProp = keystoreProperties["storeType"] as? String

                if (!keyAliasProp.isNullOrBlank())       keyAlias = keyAliasProp
                if (!storeFileProp.isNullOrBlank())       storeFile = file(storeFileProp)
                if (!storePasswordProp.isNullOrBlank())   storePassword = storePasswordProp

                // Defensive fallback: use storePassword when keyPassword is
                // absent or blank — matches CI workflow store=key fallback and
                // covers PKCS#12 keystores that share a single password.
                keyPassword = if (!keyPasswordProp.isNullOrBlank()) {
                    keyPasswordProp
                } else if (!storePasswordProp.isNullOrBlank()) {
                    storePasswordProp
                } else {
                    null
                }

                if (!storeTypeProp.isNullOrBlank())      storeType = storeTypeProp
            }
        }
    }

    buildTypes {
        release {
            // Point release builds at the release signing config unconditionally.
            // If any signing field is invalid (missing key.properties, missing
            // keyAlias, blank password, non-existent keystore ...), the
            // applicationVariants.all block BELOW will throw a GradleException
            // BEFORE any task executes. This guarantees:
            //   ✓ Debug builds are NOT affected (local dev without keys)
            //   ✓ Release builds NEVER fall back to debug signing keys
            //   ✓ A clear, actionable GradleException explains the issue
            signingConfig = signingConfigs.getByName("release")
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
        // ABI-specific versionCode override (splits support).
        //
        // Uses reflection + try/catch to stay compatible across AGP versions:
        //   - AGP 7.x/8.x had ApkVariantOutputImpl (internal class) + OutputFile.ABI
        //   - AGP 9.x removed/refactored both internals
        // If the reflection-based probe fails, we simply skip the override — the
        // build still succeeds with a single universal versionCode. This block
        // only matters for split APK builds (multiple ABI APKs); CI uses
        // `flutter build apk --target-platform android-arm64` which produces a
        // SINGLE arm64 APK, so the override isn't even needed in practice.
        variant.outputs.forEach { output ->
            val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
            try {
                val outputCls = output.javaClass

                // --- 1. Read ABI filter via getFilter(String) ---
                var abiName: String? = null
                try {
                    // com.android.build.OutputFile.ABI = "ABI"
                    val getFilter = outputCls.getMethod("getFilter", String::class.java)
                    abiName = getFilter.invoke(output, "ABI") as? String
                } catch (_: Throwable) {}

                if (abiName != null) {
                    val abiCode = abiCodes[abiName]
                    if (abiCode != null) {
                        // --- 2. Set versionCodeOverride via setter ---
                        val newCode = variant.versionCode * 100 + abiCode
                        try {
                            val setter = outputCls.getMethod(
                                "setVersionCodeOverride",
                                Integer::class.javaPrimitiveType ?: Int::class.java
                            )
                            setter.invoke(output, newCode)
                        } catch (_: Throwable) {
                            try {
                                val setterAny = outputCls.methods.firstOrNull { m ->
                                    m.name == "setVersionCodeOverride" && m.parameterCount == 1
                                }
                                setterAny?.invoke(output, newCode)
                            } catch (_: Throwable) {}
                        }
                    }
                }
            } catch (_: Throwable) {
                // Silently skip: ABI-specific versionCodes are purely a polish
                // feature for split builds; single-APK builds work fine without.
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
