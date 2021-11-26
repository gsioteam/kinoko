package com.neo.native_main_thread;

import android.os.Handler;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** NativeMainThreadPlugin */
public class NativeMainThreadPlugin implements FlutterPlugin, MethodCallHandler {

  static NativeMainThreadPlugin current = null;

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  Handler handler;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "native_main_thread");
    channel.setMethodCallHandler(this);
    handler = new Handler();
    synchronized (NativeMainThreadPlugin.class) {
      current = this;
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    result.notImplemented();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    synchronized (NativeMainThreadPlugin.class) {
      current = null;
    }
  }

  public static void sendEvent(final String name, final String data) {
    synchronized (NativeMainThreadPlugin.class) {
      if (current != null) {
        current.handler.post(new Runnable() {
          @Override
          public void run() {
            Map<String, String> map = new HashMap<>();
            map.put("name", name);
            map.put("data", data);
            current.channel.invokeMethod("event", map);
          }
        });
      }
    }
  }

}
