pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropsFile = file("local.properties")
            if (localPropsFile.exists()) {
                localPropsFile.inputStream().use { properties.load(it) }
            }
            // Try flutter.sdk from local.properties first; fall back to FLUTTER_ROOT env
            // var; then finally try `flutter` on PATH via a shell probe. The first hit
            // wins. If ALL sources fail we throw a clearer error with remediation steps.
            val explicit = properties.getProperty("flutter.sdk")
            if (explicit != null && explicit.isNotBlank()) {
                explicit
            } else {
                val env = System.getenv("FLUTTER_ROOT")
                if (env != null && env.isNotBlank()) {
                    env
                } else {
                    // Last resort: try to locate flutter via command-line.
                    // On Windows this may return a path like: C:\src\flutter\bin\flutter.bat
                    // We need to strip the \bin\flutter.bat suffix to get the SDK root.
                    val located = try {
                        val pb = ProcessBuilder("where", "flutter")
                            .redirectErrorStream(true)
                        val proc = pb.start()
                        proc.inputStream.bufferedReader().useLines { lines ->
                            lines.firstOrNull { it.trim().endsWith("flutter.bat") || it.trim().endsWith("flutter") }
                        }?.trim()
                    } catch (_: Throwable) {
                        null
                    }
                    if (located != null) {
                        // Remove \bin\flutter(.bat) suffix (2 path levels up)
                        val f = java.io.File(located)
                        f.parentFile?.parentFile?.absolutePath
                    } else {
                        null
                    }
                }
            }.also {
                require(it != null && it.isNotBlank()) {
                    "flutter.sdk not found. Please do ONE of the following:\n" +
                        "  1) Edit android/local.properties and add: flutter.sdk=C:/path/to/flutter\n" +
                        "  2) Set the FLUTTER_ROOT environment variable\n" +
                        "  3) Add the Flutter SDK's bin/ folder to your PATH"
                }
            } as String
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
