plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

val aveluneKeystorePath = providers.environmentVariable("AVELUNE_KEYSTORE_PATH").orNull
val aveluneKeystorePassword = providers.environmentVariable("AVELUNE_KEYSTORE_PASSWORD").orNull
val aveluneKeyAlias = providers.environmentVariable("AVELUNE_KEY_ALIAS").orNull
val aveluneKeyPassword = providers.environmentVariable("AVELUNE_KEY_PASSWORD").orNull
val hasAveluneReleaseSigning = listOf(
    aveluneKeystorePath,
    aveluneKeystorePassword,
    aveluneKeyAlias,
    aveluneKeyPassword,
).all { !it.isNullOrBlank() }
if (providers.environmentVariable("AVELUNE_REQUIRE_RELEASE_SIGNING").orNull == "true" &&
    !hasAveluneReleaseSigning
) {
    throw GradleException("Stable Avelune release signing is required but incomplete.")
}

val brandResources = layout.buildDirectory.dir("generated/aveluneBrand")
val prepareAveluneBrand by tasks.registering(Sync::class) {
    from(rootProject.file("../pokemap_hub/assets/avelune/logo")) {
        include("avelune_glass_wordmark.png")
        into("drawable-nodpi")
    }
    into(brandResources)
}

android {
    namespace = "com.yoahnl.avelune.player"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.yoahnl.avelune.player"
        minSdk = 24
        targetSdk = 36
        versionCode = providers.gradleProperty("aveluneVersionCode").orElse("3").get().toInt()
        versionName = providers.gradleProperty("aveluneVersionName").orElse("1.0.1").get()
        manifestPlaceholders["surfaceProbeEnabled"] = "false"
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
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
        getByName("debug") {
            manifestPlaceholders["surfaceProbeEnabled"] = "true"
        }
        create("profile") {
            initWith(getByName("debug"))
            matchingFallbacks += "debug"
            manifestPlaceholders["surfaceProbeEnabled"] = "false"
        }
        getByName("release") {
            if (hasAveluneReleaseSigning) {
                signingConfig = signingConfigs.getByName("aveluneRelease")
            }
        }
    }

    sourceSets.getByName("main").res.srcDir(brandResources)
    packaging.resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
}

kotlin {
    jvmToolchain(17)
}

tasks.named("preBuild") {
    dependsOn(prepareAveluneBrand)
}

configurations.configureEach {
    resolutionStrategy.cacheChangingModulesFor(0, "seconds")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation(project(":host_core"))
    implementation(platform("androidx.compose:compose-bom:2025.09.01"))
    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.9.4")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.4")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("io.coil-kt:coil-compose:2.7.0")
    debugImplementation("com.yoahnl.avelune.runtime.android:flutter_debug:1.0") {
        isChanging = true
    }
    releaseImplementation("com.yoahnl.avelune.runtime.android:flutter_release:1.0") {
        isChanging = true
    }
    add("profileImplementation", "com.yoahnl.avelune.runtime.android:flutter_profile:1.0") {
        isChanging = true
    }
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
}
