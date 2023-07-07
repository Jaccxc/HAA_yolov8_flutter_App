# nir_flutter

NIR app

Things to note:
    Inorder to make release version of the app to work.
    For bluetooth plus to work:
        in ./android/app/build.gradle:
            in defaultConfig
                minSdkVersion 19 must be added.
            in buildTypes:
`                release {
                    minifyEnabled true
                    shrinkResources true    
                    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
                    signingConfig signingConfigs.debug
                }`
        in ./android/app/proguard-rules.pro:
                # for flutter_blue_plus
`                -keep class com.boskokg.flutter_blue_plus.** { *; }
                # for flutter_blue
                -keep class com.pauldemarco.flutter_blue.** { *; }`
    For bluetooth and http permission:
            in ./android/app/src/main/AndroidManifest.xml:
`                <uses-permission android:name="android.permission.BLUETOOTH" />
                <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
                <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
                <uses-permission android:name="android.permission.INTERNET" />
`