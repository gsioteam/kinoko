package com.qlp.glib;

import android.os.Handler;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** GlibPlugin */
public class GlibPlugin implements FlutterPlugin, MethodCallHandler {
  static {
    System.loadLibrary("glib");
  }

  MethodChannel channel;
  Handler handler;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
    try {
      channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "glib");
      channel.setMethodCallHandler(this);
      handler = new Handler();
      onAttached(this);
    } catch (Exception e) {

    }
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  @SuppressWarnings("deprecation")
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "glib");
    channel.setMethodCallHandler(new GlibPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    onDetached(this);
  }

  public void sendSignal() {
    handler.post(new Runnable() {
      @Override
      public void run() {
        channel.invokeMethod("sendSignal", null);
      }
    });
  }

  private native void onAttached(GlibPlugin plugin);
  private native void onDetached(GlibPlugin plugin);

  public static native void setDebug(String debug_path);
}
