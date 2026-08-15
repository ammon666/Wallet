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

// Force compileSdk = 36 for ALL Android library subprojects (Flutter plugins).
//
// WHY: Flutter plugins ship with varying compileSdk values in their build.gradle:
//   flutter_credit_card_scanner 0.12.0  → compileSdk = 34
//   google_mlkit_text_recognition 0.15.0 → compileSdk = 36
//   google_mlkit_commons 0.11.1          → compileSdk = 36
// The Android Gradle Plugin's AAR metadata check requires every module to
// have compileSdk >= the maximum among all dependencies. With the app at
// flutter.compileSdkVersion (36), any plugin below 36 triggers:
//   ":flutter_credit_card_scanner is currently compiled against android-34;
//    however, a dependency requires compileSdk 36 or higher"
//
// This block unconditionally sets every plugin's compileSdk to 36 (matching
// Flutter's default), eliminating all mismatch errors. Uses reflection because AGP
// is `apply false` in the root project, so its Kotlin DSL types
// (LibraryExtension etc.) are not on the classpath here.
//
// TIMING: We cannot use a plain `afterEvaluate` because
//   `subprojects { evaluationDependsOn(":app") }` (see block above) forces
//   subproject evaluation to happen before this block's afterEvaluate hooks
//   can be registered, resulting in:
//     "Cannot run Project.afterEvaluate(Action) when the project is already
//      evaluated."
//   So we check project.state FIRST — if the project is already evaluated
//   we run the logic synchronously; otherwise we register afterEvaluate.
subprojects {
    fun patchCompileSdk() {
        val androidExt = extensions.findByName("android") ?: return
        val cls = androidExt.javaClass
        try {
            val setter = cls.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
            setter.invoke(androidExt, 36)
        } catch (e: NoSuchMethodException) {
            try {
                val setter = cls.getMethod("setCompileSdk", Integer::class.java)
                setter.invoke(androidExt, 36)
            } catch (e2: NoSuchMethodException) {
                // Not an Android extension or unsupported API — skip
            }
        }
    }

    if (project.state.executed) {
        patchCompileSdk()
    } else {
        afterEvaluate { patchCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
