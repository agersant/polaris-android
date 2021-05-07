object Deps {

    const val androidGradlePlugin = "com.android.tools.build:gradle:4.2.0"

    object Kotlin {
        const val version = "1.5.0"
        const val gradlePlugin = "org.jetbrains.kotlin:kotlin-gradle-plugin:$version"
        const val stdlib = "org.jetbrains.kotlin:kotlin-stdlib-jdk8:$version"
    }

    object Androidx {
        const val appcompat = "androidx.appcompat:appcompat:1.3.0-rc01"
        const val coreKtx = "androidx.core:core-ktx:1.3.2"
        const val preferenceKtx = "androidx.preference:preference-ktx:1.1.1"
        const val media = "androidx.media:media:1.3.1"
    }
    

    object Nav {
        const val version = "2.3.5"
        const val fragmentKtx = "androidx.navigation:navigation-fragment-ktx:$version"
        const val uiKtx = "androidx.navigation:navigation-ui-ktx:$version"
    }

    object ExoPlayer {
        const val version = "2.13.3"
        const val core = "com.google.android.exoplayer:exoplayer-core:$version"
        const val flacExtension = "com.github.Saecki.ExoPlayer-Extensions:extension-flac:$version"
    }

    const val material = "com.google.android.material:material:1.3.0"

    const val gson = "com.google.code.gson:gson:2.8.6"
    const val okhttp = "com.squareup.okhttp3:okhttp:4.9.1"

    const val swipyRefresh = "com.github.orangegangsters:swipy:1.2.3@aar"
}
