allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid = {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val method = android.javaClass.getMethod("setNdkVersion", String::class.java)
                    method.invoke(android, "28.2.13676358")
                } catch (_: Exception) {}
                try {
                    val method = android.javaClass.getMethod("setCompileSdkVersion", Integer.TYPE)
                    method.invoke(android, 36)
                } catch (_: Exception) {
                    try {
                        val method = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                        method.invoke(android, 36)
                    } catch (_: Exception) {
                        try {
                            val method = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                            method.invoke(android, "android-36")
                        } catch (_: Exception) {}
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
