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

// Plugin lama (mis. file_picker 8, compileSdk 34) gagal build saat
// dependensinya menuntut compileSdk 36. Paksa 36 ke semua subproject
// via refleksi (tanpa import kelas AGP agar script selalu kompilasi):
// API yang dipakai plugin stabil, dibuktikan build CI.
subprojects {
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
            ?: return@afterEvaluate
        try {
            val getter =
                androidExt.javaClass.getMethod("getCompileSdk")
            val setter = androidExt.javaClass.getMethod(
                "setCompileSdk", Int::class.javaPrimitiveType)
            val current = getter.invoke(androidExt) as? Int ?: 0
            if (current in 1..35) {
                setter.invoke(androidExt, 36)
            }
        } catch (e: Exception) {
            logger.warn(
                "[root] lewati paksa compileSdk "
                "untuk ${project.name}: ${e.message}")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
