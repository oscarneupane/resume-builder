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
// Some plugins (e.g. file_picker) still declare compileSdk 34, but their
// transitive flutter_plugin_android_lifecycle now requires consumers to compile
// against 36+. Force every Android plugin subproject up to 36 so the AAR
// metadata check passes. Uses withGroovyBuilder to avoid importing AGP types
// into this Kotlin DSL script. This block MUST come before the
// evaluationDependsOn block below, otherwise afterEvaluate would be registered
// after the project is already evaluated.
subprojects {
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            androidExtension.withGroovyBuilder {
                "compileSdkVersion"(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
