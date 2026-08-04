plugins {
    id("com.android.library") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "2.0.21"
}

android {
    namespace = "org.godotengine.plugin.quickactionsappshortcuts"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

dependencies {
    // Trampoline-only AAR: no Godot dependency required.
}

tasks.register("copyAarToAddon") {
    dependsOn("assembleDebug", "assembleRelease")
    doLast {
        val addonBin = rootProject.projectDir.resolve("../addons/QuickActionsAppShortcutsPlugin/bin")
        val aarDir = layout.buildDirectory.dir("outputs/aar").get().asFile
        listOf("debug", "release").forEach { variant ->
            val source = aarDir.listFiles()?.firstOrNull {
                it.name.endsWith("-$variant.aar")
            } ?: error("Missing $variant AAR in ${aarDir.absolutePath}")
            val targetDir = addonBin.resolve(variant)
            targetDir.mkdirs()
            val target = targetDir.resolve("QuickActionsAppShortcutsPlugin-$variant.aar")
            source.copyTo(target, overwrite = true)
            println("Copied ${source.name} -> ${target.absolutePath}")
        }
    }
}
