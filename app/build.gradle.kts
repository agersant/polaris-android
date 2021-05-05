plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    compileSdkVersion(30)
    ndkVersion = "22.1.7171670"

    defaultConfig {
        minSdkVersion(23)
        targetSdkVersion(30)

        applicationId = "agersant.polaris"
        versionName = "0.0"
        versionCode = 1
    }
    signingConfigs {
        create("release") {
            storeFile = File(System.getenv("SIGNING_KEYSTORE_PATH").orEmpty())
            storePassword = System.getenv("SIGNING_KEYSTORE_PASSWORD").orEmpty()
            keyAlias = System.getenv("SIGNING_KEY_ALIAS").orEmpty()
            keyPassword = System.getenv("SIGNING_KEY_PASSWORD").orEmpty()
        }
    }
    buildTypes {
        getByName("release") {
            debuggable(false)
            minifyEnabled(false)

            proguardFiles(getDefaultProguardFile("proguard-android.txt"))
            proguardFiles("proguard-rules.pro")
            signingConfig = signingConfigs["release"]
        }
        getByName("debug") {
            debuggable(true)
        }
    }
    buildFeatures {
        viewBinding = true
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation(fileTree("dir" to "libs", "include" to "*.jar")) // TODO: find out if we need this

    // Core
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:${Versions.kotlin}")
    implementation("androidx.core:core-ktx:1.3.2")
    implementation("androidx.appcompat:appcompat:1.3.0-rc01")
    implementation("com.google.android.material:material:1.3.0")

    // Navigation
    implementation("androidx.navigation:navigation-fragment-ktx:${Versions.navigation}")
    implementation("androidx.navigation:navigation-ui-ktx:${Versions.navigation}")

    // Preference
    implementation("androidx.preference:preference-ktx:1.1.1")

    // Media session
    implementation("androidx.media:media:1.3.1")

    // Media player
    implementation("com.google.android.exoplayer:exoplayer-core:2.13.3")
    implementation("com.github.Saecki.ExoPlayer-Extensions:flac:2.13.3")

    // Rest client
    implementation("com.google.code.gson:gson:2.8.6")
    implementation("com.squareup.okhttp3:okhttp:4.9.1")

    // Swipe refresh layout
    implementation("com.github.orangegangsters:swipy:1.2.3@aar")
}

task("printVersionCode") {
    doLast {
        println(android.defaultConfig.versionCode)
    }
}

task("printVersionName") {
    doLast {
        println(android.defaultConfig.versionName)
    }
}
