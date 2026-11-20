# Keep annotations and signatures required by some libraries
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep Room databases (Fixes WorkDatabase instantiation crash in Release mode)
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**

# BetterPlayer & ExoPlayer
-keep class com.jhomlala.better_player.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
