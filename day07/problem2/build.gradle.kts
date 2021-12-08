plugins {
    java
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(7))
    }
}

dependencies {
    implementation(files("../pizza-1.1.jar"))
}

sourceSets.main {
    java {
        srcDir(layout.projectDirectory.dir("src/main/pizza"))
    }
}

val compilePizza by tasks.registering(JavaExec::class) {
    val input = sourceSets.main.map { it.allSource }
    inputs.files(input)

    val output = layout.buildDirectory.dir("classes/pizza").map { it.asFile.absolutePath }
    outputs.dir(output)

    classpath(configurations.compileClasspath)

    doFirst {
        val jdkPath = javaToolchains.compilerFor {
            languageVersion.set(JavaLanguageVersion.of(7))
        }.get().metadata.installationPath

        val jdkJar = jdkPath.file("jre/lib/rt.jar").asFile.absolutePath
        val pizzaJar = configurations.compileClasspath.get().singleFile.absolutePath

        args("-pizza", "-classpath", "$jdkJar:$pizzaJar")
        args("-d", output.get())
        args(input.get().files.map { it.absolutePath })
    }
}

val pizzaJar by tasks.registering(Jar::class) {
    from(compilePizza)
    from(zipTree(configurations.compileClasspath.get().singleFile)) {
        include("/pizza/**")
    }

    manifest {
        attributes("Main-Class" to "dev.denwav.aoc2021d7p2.Solution")
    }
}

val runPizza by tasks.registering(JavaExec::class) {
    classpath(pizzaJar)
    args("../input.txt")
}
