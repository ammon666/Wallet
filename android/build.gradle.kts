allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force compileSdk ≥ 35 for all Android library subprojects (Flutter plugins).
//
// WHY: Some Flutter plugins (e.g. flutter_credit_card_scanner 0.12.0) ship
// with compileSdk=34 in their build.gradle, but their transitive dependencies
// (google_mlkit_text_recognition, google_mlkit_commons) require compileSdk ≥ 35.
// This causes AAR metadata check failures at build time:
//   ":flutter_credit_card_scanner is currently compiled against android-34"
//
// This block transparently upgrades the plugin's compileSdk to 35 without
// forking the plugin. Uses reflection because AGP is `apply false` in the
// root project, so its Kotlin DSL types (LibraryExtension etc.) are not on
// the classpath here.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val cls = androidExt.javaClass
            val getter = cls.getMethod("getCompileSdk")
            val current = getter.invoke(androidExt) as? Int
            if (current == null || current < 35) {
                try {
                    val setter = cls.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    setter.invoke(androidExt, 35)
                } catch (e: NoSuchMethodException) {
                    val setter = cls.getMethod("setCompileSdk", Integer::class.java)
                    setter.invoke(androidExt, 35)
                }
            }
        } catch (e: NoSuchMethodException) {
            // Not an Android extension — skip
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
