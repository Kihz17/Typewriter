import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

repositories {
}
dependencies {
    api("com.extollit.gaming:hydrazine-path-engine:1.8.2")
    implementation("com.github.bsommerfeld:pathetic:5.3.1")
    implementation("com.github.bsommerfeld.pathetic-bukkit:core:5.3.0")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "RoadNetwork"
        shortDescription = "Natural Pathfinding for NPCs and Players"
        description = """
            |The road network is a way to create natural paths in the world. 
            |It can be used by NPCs to navigate to certain locations, or by players to know how to get somewhere.
            """.trimMargin()

        engineVersion = rootProject.file("../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper()
    }
}

val isDebugBuild = project.findProperty("debug") == "true"

tasks.withType<KotlinCompile>().configureEach {
    doFirst {
        if (isDebugBuild) {
            println("→ [KotlinCompile] Running in DEBUG mode with -Xno-optimize, -Xno-inline")
        }
    }

    compilerOptions {
        if (isDebugBuild) {
            freeCompilerArgs.add("-Xdebug")
        }
    }
}

