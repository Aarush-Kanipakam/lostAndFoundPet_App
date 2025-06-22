// android/build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.Project
import org.gradle.kotlin.dsl.repositories

plugins {
    // 🔥 Firebase plugin (Kotlin DSL syntax)
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 👇 VERY IMPORTANT: Automatically apply the Firebase plugin to app module
    afterEvaluate {
        if (project.name == "app") {
            project.plugins.apply("com.google.gms.google-services")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
