// Top-level build file where you can add configuration options common to all sub-projects/modules.s

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath(Deps.androidGradlePlugin)
        classpath(Deps.Kotlin.gradlePlugin)

        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle.kts files
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
        maven("https://dl.bintray.com/google/exoplayer")
    }
}
