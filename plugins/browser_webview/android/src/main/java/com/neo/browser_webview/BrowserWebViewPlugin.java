package com.neo.browser_webview;

import android.content.Context;
import android.os.Build;
import android.os.Parcelable;
import android.util.JsonReader;
import android.util.Log;
import android.util.SparseArray;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.ValueCallback;
import android.webkit.WebBackForwardList;
import android.webkit.WebHistoryItem;
import android.webkit.WebView;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** BrowserWebviewPlugin */
public class BrowserWebViewPlugin implements FlutterPlugin,
        MethodCallHandler,
        WebViewContainer.CallbackInterface,
        BrowserWebViewFactory.IGetContainer {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context;
  private Map<Object, WebViewContainer> containers = new HashMap<>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "browser_webview");
    channel.setMethodCallHandler(this);

    context = flutterPluginBinding.getApplicationContext();
    flutterPluginBinding
            .getPlatformViewRegistry()
            .registerViewFactory("browser_web_view", new BrowserWebViewFactory(this));
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    if (call.method.equals("init")) {
      WebViewContainer container = new WebViewContainer(context, (Map<String, Object>)call.arguments, channel);
      container.onCallback = this;

      Number id = call.argument("id");
      if (id != null) {
        containers.put(id, container);
        result.success(true);
      } else {
        result.success(false);
      }

    } else if (call.method.equals("dispose")) {
      Number id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.remove(id);
        if (container != null) {
          container.onCallback = null;
          container.getWebView().destroy();
        }
      }
      result.success(null);
    } else if (call.method.equals("loadUrl")) {
      Object id = call.argument("id");
      String url = call.argument("url");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.getWebView().loadUrl(url);
        }
      }
      result.success(null);
    } else if (call.method.equals("takeCapture")) {
      Object id = call.argument("id");
      Number width = call.argument("width");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        container.takeCapture(width.intValue(), new WebViewContainer.ITackCaptureCallback() {
          @Override
          public void onComplete(String path) {
            Map res = new HashMap();
            res.put("path", path);
            result.success(res);
          }

          @Override
          public void onFailed(String msg) {
            Map res = new HashMap();
            res.put("error", msg);
            result.success(res);
          }
        });
      } else {
        Map<String, Object> res = new HashMap<>();
        res.put("error", "no id");
        result.success(res);
      }
    } else if (call.method.equals("getHistoryList")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        WebBackForwardList historyList = container.getWebView().copyBackForwardList();
        List<Object> arr = new ArrayList<>();
        for (int i = 0, t = historyList.getSize(); i < t; ++i) {
          WebHistoryItem item = historyList.getItemAtIndex(i);
          Map<String, Object> map = new HashMap<>();
          map.put("title", item.getTitle());
          map.put("url", item.getUrl());
          if (historyList.getCurrentIndex() == i) {
            map.put("current", true);
          }
          arr.add(map);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("list", arr);
        result.success(res);
      } else {
        Map<String, Object> res = new HashMap<>();
        res.put("error", "no id");
        result.success(res);
      }
    } else if (call.method.equals("reload")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.getWebView().reload();
        }
      }
      result.success(null);
    } else if (call.method.equals("goBack")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.getWebView().goBack();
        }
      }
      result.success(null);
    } else if (call.method.equals("goForward")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.getWebView().goForward();
        }
      }
      result.success(null);
    } else if (call.method.equals("eval")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          String script = call.argument("script");
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            container.getWebView().evaluateJavascript(script, new ValueCallback<String>() {
              @Override
              public void onReceiveValue(String value) {
                Map<String, Object> res = new HashMap<>();
                res.put("result", value);
                res.put("$json_parse", true);
                result.success(res);
              }
            });
          }
        } else {
          result.success(null);
        }
      } else {
        result.success(null);
      }
    } else if (call.method.equals("stop")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.getWebView().stopLoading();
        }
      }
      result.success(null);
    } else if (call.method.equals("makeOffscreen")) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          container.makeOffScreen();
        }
      }
      result.success(null);
    } else if (call.method.equals("clear")) {
      String type = call.argument("type");
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        if ("cookies".equals(type)) {
          CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
            @Override
            public void onReceiveValue(Boolean value) {
              result.success(value);
            }
          });
        } else if ("session".equals(type)) {
          CookieManager.getInstance().removeSessionCookies(new ValueCallback<Boolean>() {
            @Override
            public void onReceiveValue(Boolean value) {
              result.success(value);
            }
          });
        } else if ("cache".equals(type)) {
          WebView webView = new WebView(context);
          webView.clearCache(true);
          webView.clearFormData();
          result.success(true);
        } else {
          result.success(false);
        }
      } else {
        if ("cookies".equals(type)) {
          CookieSyncManager cookieSyncMngr = CookieSyncManager.createInstance(context);
          cookieSyncMngr.startSync();
          CookieManager.getInstance().removeAllCookie();
          cookieSyncMngr.stopSync();
          cookieSyncMngr.sync();
          result.success(true);
        } else if ("session".equals(type)) {
          CookieSyncManager cookieSyncMngr = CookieSyncManager.createInstance(context);
          cookieSyncMngr.startSync();
          CookieManager.getInstance().removeSessionCookie();
          cookieSyncMngr.stopSync();
          cookieSyncMngr.sync();
          result.success(true);
        } else if ("cache".equals(type)) {
          WebView webView = new WebView(context);
          webView.clearCache(true);
          webView.clearFormData();
          result.success(true);
        } else {
          result.success(false);
        }
      }

    } else if ("setDownloadDetector".equals(call.method)) {
      Object id = call.argument("id");
      if (id != null) {
        WebViewContainer container = containers.get(id);
        if (container != null) {
          List<String> extensions = call.argument("extensions");
          container.setDownloadDetector(extensions);
        }
      }
      result.success(null);
    } else if ("getCookies".equals(call.method)) {
      String cookies = CookieManager.getInstance().getCookie((String)call.argument("url"));
      String[] temp=cookies.split(";");
      List<Map<String, String>> results = new ArrayList<>();
      for (String ar1 : temp ){
        int index = ar1.indexOf("=");
        Map<String, String> map = new HashMap<>();
        if (index >= 0) {
          map.put("name", ar1.substring(0, index));
          map.put("value", ar1.substring(index + 1));
        } else {
          map.put("name", ar1);
          map.put("value", "");
        }
        results.add(map);
      }
      Map map = new HashMap();
      map.put("cookies", results);
      result.success(map);
    } else if ("setScrollEnabled".equals(call.method)) {
      // To be implemented
      result.notImplemented();
    } else if ("setEnablePullDown".equals(call.method)) {
      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public WebViewContainer find(Object id) {
    return containers.get(id);
  }

  @Override
  public void onCreateSubWindow(WebViewContainer container, WebViewContainer subContainer) {
    if (subContainer.id != null) {
      containers.put(subContainer.id, subContainer);
    }
  }
}
