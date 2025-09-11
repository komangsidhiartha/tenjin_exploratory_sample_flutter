buildscript {
    val kotlin_version = "1.9.0" // This is a common version, but verify yours
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add the Android Gradle Plugin and Kotlin Plugin
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")

        // Add the classpath dependencies here
        classpath("com.android.installreferrer:installreferrer:1.1.2")
        classpath("com.google.android.gms:play-services-analytics:17.0.0")
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
