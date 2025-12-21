package com.qlp.glib;

import android.os.Handler;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

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

}
