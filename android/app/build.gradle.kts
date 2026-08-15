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
        val buildType = variant.buildType.name

        // -------------------------------------------------------------------
        // Hard constraint enforcement:
        // Release builds MUST use a custom keystore (.jks/.p12) via
        // key.properties — they MUST NOT silently fall back to the auto-
        // generated debug.keystore. Any failure aborts with GradleException
        // BEFORE compilation starts so the CI build fails with a clear error.
        // -------------------------------------------------------------------
        if (buildType == "release") {
            val reasons = mutableListOf<String>()

            if (!keystorePropertiesFile.exists()) {
                reasons.add(
                    "key.properties not found at " +
                        "${keystorePropertiesFile.absolutePath}. This file is " +
                        "gitignored and must be created locally (for dev release " +
                        "builds) or injected by the CI workflow (from GitHub " +
                        "Secrets: KEYSTORE_FILE encoded as base64)."
                )
            }

            val sc = variant.signingConfig
            if (sc == null) {
                reasons.add(
                    "release variant has a null signingConfig — the release " +
                        "buildType is not wired to a signing configuration."
                )
            } else {
                val alias = sc.keyAlias
                if (alias.isNullOrBlank()) {
                    reasons.add("signingConfig.keyAlias is null or blank. Check key.properties 'keyAlias' entry.")
                }

                val sf = sc.storeFile
                if (sf == null) {
                    reasons.add("signingConfig.storeFile is null. Check key.properties 'storeFile' entry.")
                } else if (!sf.exists()) {
                    reasons.add(
                        "signingConfig.storeFile references non-existent " +
                            "keystore: ${sf.absolutePath}. Paths are resolved " +
                            "relative to the android/ directory of the project."
                    )
                } else {
                    // Paranoia check: make absolutely sure we're not signing a
                    // release build with the auto-generated debug.keystore
                    // (lives in ~/.android/debug.keystore). This catches the
                    // case where someone wired signingConfigs.debug into the
                    // release buildType, or pointed storeFile at debug.keystore
                    // manually. Note: SigningConfig.name is not available on
                    // AGP 9.0+ (android.newDsl=true), so we check the file path
                    // instead — same protective effect, API-stable.
                    val ksPath = sf.absolutePath.lowercase()
                    if (ksPath.endsWith("debug.keystore") || ksPath.contains("/.android/")) {
                        reasons.add(
                            "signingConfig.storeFile points to a debug " +
                                "keystore: ${sf.absolutePath}. Release APKs " +
                                "MUST use a custom .jks/.p12 keystore from " +
                                "key.properties, NEVER the auto-generated " +
                                "debug.keystore from ~/.android."
                        )
                    }
                }

                if (sc.storePassword.isNullOrBlank()) {
                    reasons.add("signingConfig.storePassword is null or blank. Check key.properties 'storePassword' entry.")
                }

                if (sc.keyPassword.isNullOrBlank()) {
                    reasons.add(
                        "signingConfig.keyPassword is null or blank even after " +
                            "the storePassword fallback. Key entries require a " +
                            "non-empty password."
                    )
                }
            }

            if (reasons.isNotEmpty()) {
                val sb = StringBuilder()
                sb.appendLine("============================================================")
                sb.appendLine("[RELEASE SIGNING FAILURE] Hard constraint violation:")
                sb.appendLine("release builds MUST use a custom keystore (.jks/.p12)")
                sb.appendLine("and MUST NOT fall back to debug signing.")
                sb.appendLine("------------------------------------------------------------")
                reasons.forEachIndexed { i, r -> sb.appendLine("  ${i + 1}. $r") }
                sb.appendLine("------------------------------------------------------------")
                sb.appendLine("Expected key.properties format (in android/key.properties):")
                sb.appendLine("  keyAlias=<your-key-alias>")
                sb.appendLine("  storeFile=<absolute-or-relative-path-to-.jks-or-.p12>")
                sb.appendLine("  storePassword=<keystore-password>")
                sb.appendLine("  keyPassword=<optional; defaults to storePassword>")
                sb.appendLine("  storeType=<JKS or PKCS12 (required for .p12 files)>")
                sb.appendLine("============================================================")
                throw GradleException(sb.toString())
            }
        }

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
