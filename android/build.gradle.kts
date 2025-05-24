// android/build.gradle.kts

plugins {
    // No plugins here — classic buildscript block used
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Use the latest google-services plugin version consistently
        classpath("com.android.tools.build:gradle:8.1.1")  // your AGP version (adjust if needed)
        classpath("com.google.gms:google-services:4.4.2")  // Google Services plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // Kotlin plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directories (optional, as per your original code)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
