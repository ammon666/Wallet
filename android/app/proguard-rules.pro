# ============================================================
# ProGuard / R8 keep rules for Wallet
# ============================================================

# ---- Google ML Kit Text Recognition ----
# The google_mlkit_text_recognition Flutter plugin references Chinese /
# Japanese / Korean / Devanagari text recognizer classes that are only
# available in separate ML Kit extension packages
# (text-recognition-chinese, text-recognition-japanese, etc.).
# We only use the Latin script recognizer (TextRecognitionScript.latin),
# so these classes are NEVER instantiated at runtime. Tell R8 to ignore
# the missing classes instead of failing the build.
# Without these rules R8 errors with:
#   Missing class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
#   Missing class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
#   Missing class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
#   Missing class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit model loader classes (reflection-accessed by the SDK).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }

# ---- flutter_credit_card_scanner ----
# This package brings its own Java/Kotlin classes that R8 may try to
# shrink/obfuscate. Keep the package's public API + credit_card_validator
# transitive dependency so reflection-based model loading works.
-keep class com.sudumtech.flutter_credit_card_scanner.** { *; }
-keep class com.fintasys.** { *; } # credit_card_validator native classes

# ---- Flutter / Dart ----
# Flutter's own keep rules are auto-injected by the Flutter Gradle Plugin,
# so we don't duplicate them here.
