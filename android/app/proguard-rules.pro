
# Preserve annotation attributes
-keepattributes *Annotation*

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
