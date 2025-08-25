import com.android.build.gradle.LibraryExtension
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

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
    // Mantén la evaluación de :app primero (como tenías)
    project.evaluationDependsOn(":app")
}

/**
 * ✅ Workaround AGP 8+: todos los módulos Android deben declarar "namespace".
 * Algunos plugins de terceros (p.ej., isar_flutter_libs 3.1.0+1) aún no lo definen.
 * Este bloque inyecta el namespace tan pronto se aplica el plugin 'com.android.library',
 * es decir, lo bastante temprano como para evitar el fallo de configuración.
 */
subprojects {
    plugins.withId("com.android.library") {
        if (name == "isar_flutter_libs") {
            val androidExt = extensions.findByType(LibraryExtension::class.java)
            if (androidExt != null && androidExt.namespace == null) {
                androidExt.namespace = "dev.isar.isar_flutter_libs"
                logger.lifecycle("Applied namespace to :$name -> ${androidExt.namespace}")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
