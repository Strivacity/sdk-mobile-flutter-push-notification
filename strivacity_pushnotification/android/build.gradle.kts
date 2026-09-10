group = "com.strivacity.flutter.strivacity_pushnotification"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        // Applied via buildscript classpath + apply(plugin = ...) below rather than the
        // `plugins {}` block so this module doesn't need its own version-managed plugin
        // resolution — it's built as an included subproject of the example app's Gradle build,
        // which already owns that for com.android.library/kotlin-android.
        classpath("com.diffplug.spotless:spotless-plugin-gradle:8.10.2")
        classpath("io.gitlab.arturbosch.detekt:detekt-gradle-plugin:1.23.8")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

apply(plugin = "com.diffplug.spotless")
apply(plugin = "io.gitlab.arturbosch.detekt")

android {
    namespace = "com.strivacity.flutter.strivacity_pushnotification"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }

    // Note: `com.android.build.api.dsl.Lint` on AGP 9.1.0 exposes `textReport`, not
    // `printTextReport` (confirmed by decompiling gradle-api-9.1.0.jar) — that name only
    // appears in later AGP versions.
    lint {
        abortOnError = true
        warningsAsErrors = false
        checkDependencies = true
        textReport = true
        htmlReport = true
        xmlReport = false
        sarifReport = true
        informational += "AndroidGradlePluginVersion"
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// This module has no Java sources, so only the Kotlin/ktlint block applies. Paths are relative
// to this module's own directory (`projectDir`, not `rootDir`) since this module is built as an
// included subproject.
configure<com.diffplug.gradle.spotless.SpotlessExtension> {
    kotlin {
        target("**/*.kt", "**/*.kts")
        targetExclude(
            "**/build/**/*.kt",
        )
        ktlint()
            .setEditorConfigPath("$projectDir/.editorconfig")
            .editorConfigOverride(
                mapOf(
                    "ktlint_standard_package-name" to "disabled",
                    "max_line_length" to "120",
                    "indent_size" to "4",
                    "indent_style" to "space",
                    "ktlint_code_style" to "ktlint_official",
                    "ij_kotlin_allow_trailing_comma" to "true",
                    "ij_kotlin_allow_trailing_comma_on_call_site" to "true",
                    "ktlint_function_signature_rule_force_multiline_when_parameter_count_greater_or_equal_than" to
                        "2",
                    "ktlint_class_signature_rule_force_multiline_when_parameter_count_greater_or_equal_than" to
                        "1",
                    "ktlint_chain_method_rule_force_multiline_when_chain_operator_count_greater_or_equal_than" to
                        "4",
                    "ktlint_function_signature_body_expression_wrapping" to "multiline",
                    "ktlint_property_naming_constant_naming" to "screaming_snake_case",
                    "ktlint_enum_entry_name_casing" to "upper_or_camel_cases",
                ),
            )
    }
}

configure<io.gitlab.arturbosch.detekt.extensions.DetektExtension> {
    buildUponDefaultConfig = true
    allRules = false
    parallel = true
    config.setFrom("$projectDir/config/detekt/detekt.yml")
}

tasks.withType<io.gitlab.arturbosch.detekt.Detekt>().configureEach {
    jvmTarget = "17"
    reports {
        html.required.set(true)
        xml.required.set(false)
        sarif.required.set(true)
        txt.required.set(false)
    }
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
