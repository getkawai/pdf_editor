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

// Fix for google_mlkit_commons namespace issue with AGP 8.x
gradle.beforeProject {
    if (name == "google_mlkit_commons") {
        plugins.apply("com.android.library")
        configure<com.android.build.gradle.LibraryExtension> {
            namespace = "com.google.mlkit.common"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
