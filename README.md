# Tenjin Flutter SDK: An Integration Journey

This repository documents my hands-on exploration of the [Tenjin Flutter SDK](https://github.com/tenjin/tenjin-flutter-sdk). The goal was to simulate a real-world integration into a new Flutter project, identify potential hurdles a first-time developer might face, and document the solutions.

This exercise serves as a practical evaluation of the SDK's developer experience (DX) from a fresh perspective.

## The Integration Chronology

My process followed these steps, including the challenges encountered and the resolutions discovered along the way.

### 1. Initial Project Setup & Gradle-Kotlin Incompatibility

After creating a new Flutter project and adding the `tenjin_sdk_flutter` dependency, the initial Android build failed with a Kotlin compilation error:

```
e: .../flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:758:21 Unresolved reference: filePermissions
...
FAILURE: Build failed with an exception.
* What went wrong:
  Execution failed for task ':gradle:compileKotlin'.
```


**Diagnosis:** This error pointed to an incompatibility between the project's Gradle version and the Kotlin plugin, triggered by my local Flutter environment configuration. It served as the first environmental roadblock in the integration process.

### 2. The Second Hurdle: JDK Environment Mismatch

Upon resolving the initial Gradle issue, a new problem surfaced: the Android project required JDK 21. My system, however, was configured to default to JDK 17 via the `JAVA_HOME` variable in my `.zshrc` file.

**Diagnosis & Resolution:**

* Even though I had JDK 21 installed and configured it within IntelliJ IDEA's Gradle settings, the shell's `JAVA_HOME` environment variable took precedence, causing the build to fail.
* **Solution:** Removing the explicit `JAVA_HOME` export from `.zshrc` allowed the IDE's project-specific JDK configuration to take effect, finally enabling a successful build.

### 3. The Mystery: Understanding the Data Flow

With the application running, I implemented the `TenjinSDK.connect()` and event-tracking calls. I initially monitored the "Live Test Device Data" page on the Tenjin dashboard, but no events appeared. This led me to believe the data was not being received at all.

**Investigation & Discovery:**
My initial assumption was incorrect. The issue wasn't that the events weren't being sent, but rather my understanding of the dashboard's features.

1.  **"Live Test" vs. "Custom Events":** I discovered that the "Live Test Device Data" page is a specific tool that **only displays data from devices explicitly registered as a Test Device**. My events were, in fact, being successfully received the entire time, which I confirmed by viewing them on the main **Custom Events dashboard**.
2.  **The New Mystery - User Attribution:** While checking the Custom Events dashboard, I noticed a critical issue. All incoming events, from every device that didn't have the `AD_ID` permission, were being logged under the **exact same advertising ID:** `00000000-0000-0000-0000-000000000000`.

This revealed a much more significant issue than a testing inconvenience: without the proper permission, the SDK cannot differentiate between users.

### 4. The Key Insight: `AD_ID` is Essential for User Attribution

The root cause of the aggregated data was the missing `AD_ID` permission. The Tenjin SDK requires this permission to retrieve the unique Google Advertising ID (GAID) for each device.

**Resolution & Impact:**

1.  I added the following permission to `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />
    ```
2.  Upon relaunching the app, the Tenjin dashboard immediately began receiving events with the device's unique GAID. This correctly attributed the data to my specific device.

This confirmed that the `AD_ID` permission is not just a requirement for the "Live Test" feature, but is **fundamental to the SDK's core functionality of user-level tracking and attribution**.

### 5. The Third Hurdle (iOS): Thread Performance Warning

After resolving the Android issues, I proceeded to test the integration on iOS. While the app built successfully and sent events correctly, Xcode's console produced a recurring performance warning during runtime:

```
Thread Performance Checker: Thread running at QOS_CLASS_USER_INTERACTIVE waiting on a thread without a QoS class specified. Investigate ways to avoid priority inversions
PID: 2498, TID: 445444
Backtrace
=================================================================
3   Flutter                       0x00000001071af794 _ZNSt3_fl10__function6__funcIZN7flutter8Animator10AwaitVSyncEvE3$_0NS_9allocatorIS4_EEFvNS_10unique_ptrINS2_20FrameTimingsRecorderENS_14default_deleteIS8_EEEEEEclEOSB_ + 592
4   Flutter                       0x00000001071e0c00 _ZNSt3_fl10__function6__funcIZN7flutter11VsyncWaiter12FireCallbackEN3fml9TimePointES5_bE3$_0NS_9allocatorIS6_EEFvvEEclEv + 956
5   Flutter                       0x0000000106e29618 _ZN3fml15MessageLoopImpl10FlushTasksENS_9FlushTypeE + 340
6   Flutter                       0x0000000106e2da88 _ZN3fml17MessageLoopDarwin11OnTimerFireEP16__CFRunLoopTimerPS0_ + 32
7   CoreFoundation                0x00000001af7fdbb0 55B9BA28-4C5C-3FE7-9C47-4983337D6E83 + 793520
8   CoreFoundation                0x00000001af7bede4 55B9BA28-4C5C-3FE7-9C47-4983337D6E83 + 536036
9   CoreFoundation                0x00000001af7680fc 55B9BA28-4C5C-3FE7-9C47-4983337D6E83 + 180476
10  CoreFoundation                0x00000001af7b15bc 55B9BA28-4C5C-3FE7-9C47-4983337D6E83 + 480700
11  CoreFoundation                0x00000001af7b5d20 CFRunLoopRunSpecific + 584
12  GraphicsServices              0x00000001e7885998 GSEventRunModal + 160
13  UIKitCore                     0x00000001b1a4834c 1242978A-2C2C-3781-8D6C-9777EDCE2804 + 3609420
14  UIKitCore                     0x00000001b1a47fc4 UIApplicationMain + 312
15  libswiftUIKit.dylib           0x00000001b79d2ddc $s5UIKit17UIApplicationMainys5Int32VAD_SpySpys4Int8VGGSgSSSgAJtF + 100
16  Runner.debug.dylib            0x000000010438c5d0 $sSo21UIApplicationDelegateP5UIKitE4mainyyFZ + 128
17  Runner.debug.dylib            0x000000010438c540 $s6Runner11AppDelegateC5$mainyyFZ + 44
18  Runner.debug.dylib            0x000000010438c64c __debug_main_executable_dylib_entry_point + 28
19  dyld                          0x00000001ccf74344 199941A5-95EE-3054-8E54-AE6387A9FA9A + 82756
```

**Diagnosis:** This warning, known as a "priority inversion," indicates that the main UI thread (which runs at a high priority) is being forced to wait for work happening on a lower-priority background thread. While this is not a crash, it can lead to UI stutters or unresponsiveness. Since the warning appears after adding the SDK, it suggests that some of its initialization or networking work on iOS might be interacting with the main thread sub-optimally.

## Key Findings & Developer Experience (DX) Suggestions

This investigation highlights three key areas where the developer onboarding experience can be enhanced:

1.  **Clarify Dashboard Functionality:** The documentation should explicitly state that the "Live Test Device Data" view requires manual device registration. A brief note could prevent developers from mistakenly thinking their integration is failing.
2.  **Emphasize `AD_ID`'s Critical Role for Android:** The `AD_ID` permission should be presented in the setup guide as a **mandatory requirement for accurate user attribution on Android**. The documentation should warn that omitting it will result in all data being aggregated under a null ID, rendering user-level analytics ineffective.
3.  **Investigate iOS Thread Performance:** The SDK triggers a "Thread Performance Checker" warning on iOS. An investigation into the SDK's threading behavior would be beneficial to ensure all non-UI work is performed asynchronously on appropriately prioritized background threads, preventing potential impact on UI smoothness.

## Conclusion

The Tenjin SDK is robust and correctly processes incoming data once configured. The key takeaway from this integration journey is the critical importance of platform-specific prerequisites (`AD_ID` on Android) and performance considerations (threading on iOS). A few strategic clarifications in the documentation would ensure developers can leverage the full power of the SDK's attribution capabilities from the very beginning, leading to a smoother and more effective onboarding experience.
