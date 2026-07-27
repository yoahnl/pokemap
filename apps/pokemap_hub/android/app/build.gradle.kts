plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val aveluneKeystorePath = System.getenv("AVELUNE_KEYSTORE_PATH")
val aveluneKeystorePassword = System.getenv("AVELUNE_KEYSTORE_PASSWORD")
val aveluneKeyAlias = System.getenv("AVELUNE_KEY_ALIAS")
val aveluneKeyPassword = System.getenv("AVELUNE_KEY_PASSWORD")
val hasAveluneReleaseSigning = listOf(
    aveluneKeystorePath,
    aveluneKeystorePassword,
    aveluneKeyAlias,
    aveluneKeyPassword,
).all { !it.isNullOrBlank() }
val requireAveluneReleaseSigning =
    System.getenv("AVELUNE_REQUIRE_RELEASE_SIGNING") == "true"

if (requireAveluneReleaseSigning && !hasAveluneReleaseSigning) {
    throw GradleException(
        "Stable Avelune release signing is required but incomplete.",
    )
}

android {
    namespace = "com.yoahnl.avelune.player"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yoahnl.avelune.player"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasAveluneReleaseSigning) {
            create("aveluneRelease") {
                storeFile = file(aveluneKeystorePath!!)
                storePassword = aveluneKeystorePassword
                keyAlias = aveluneKeyAlias
                keyPassword = aveluneKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasAveluneReleaseSigning) {
                signingConfigs.getByName("aveluneRelease")
            } else {
                // Local preview builds remain installable without release
                // credentials. Tagged GitHub releases set the fail-closed flag.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
