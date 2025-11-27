plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Mantém o desugaring ativado (necessário para o pacote de notificações)
        isCoreLibraryDesugaringEnabled = true

        // MANTENDO JAVA 11 COMO VOCÊ TINHA
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// --- A PEÇA QUE FALTAVA ---
dependencies {
    // Esta linha é obrigatória quando isCoreLibraryDesugaringEnabled = true
    // Usando a versão mais recente para evitar o outro erro
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}