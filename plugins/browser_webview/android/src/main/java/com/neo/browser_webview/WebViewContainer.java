package com.neo.browser_webview;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Picture;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.text.Html;
import android.text.Spanned;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.DownloadListener;
import android.webkit.JavascriptInterface;
import android.webkit.JsResult;
import android.webkit.MimeTypeMap;
import android.webkit.URLUtil;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ScrollView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import org.jsoup.Jsoup;
import org.jsoup.internal.StringUtil;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class WebViewContainer {

    public interface CallbackInterface {
        void onCreateSubWindow(WebViewContainer container, WebViewContainer subContainer);
    }

    class ResourceReplacement {
        Pattern test;
        String mimeType;
        String resource;
    }

    MethodChannel channel;
    Context context;

    CallbackInterface onCallback;
    List<String> beginScripts = new ArrayList<>();
    List<String> endScripts = new ArrayList<>();

    List<ResourceReplacement> resourceReplacements = new ArrayList<>();

    WebView webView;
    Object id;

    WebChromeClient webChromeClient = new WebChromeClient() {
        @Override
        public void onProgressChanged(WebView view, int newProgress) {
            super.onProgressChanged(view, newProgress);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("progress", newProgress / 100.0);
            channel.invokeMethod("onProgress", map);
        }

        @Override
        public void onReceivedTitle(WebView view, String title) {
            super.onReceivedTitle(view, title);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("title", title);
            channel.invokeMethod("titleChanged", map);
        }

        @Override
        public boolean onJsAlert(WebView view, String url, String message, final JsResult result) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", url);
            map.put("message", message);
            channel.invokeMethod("onAlert", map, new MethodChannel.Result() {
                @Override
                public void success(@Nullable Object res) {
                    result.confirm();
                }

                @Override
                public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                    result.cancel();
                }

                @Override
                public void notImplemented() {
                    result.cancel();
                }
            });
            return true;
        }

        @Override
        public boolean onJsConfirm(WebView view, String url, String message, final JsResult result) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", url);
            map.put("message", message);
            channel.invokeMethod("onConfirm", map, new MethodChannel.Result() {
                @Override
                public void success(@Nullable Object res) {
                    if ((boolean)res) {
                        result.confirm();
                    } else {
                        result.cancel();
                    }
                }

                @Override
                public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                    result.cancel();
                }

                @Override
                public void notImplemented() {
                    result.cancel();
                }
            });
            return true;
        }

        @Override
        public boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
            Map<String, Object> params = new HashMap<>(args);
            params.remove("id");
            WebView.HitTestResult result = view.getHitTestResult();
            String url = result.getExtra();
            params.put("url", url);
            final WebViewContainer container = new WebViewContainer(context, params, channel);
            container.id = null;

            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", url);
            channel.invokeMethod("onCreateWindow", map, new MethodChannel.Result() {
                @Override
                public void success(@Nullable Object result) {
                    Map<Object, Object> res = (Map<Object, Object>)result;
                    container.id = res.get("id");
                    onCallback.onCreateSubWindow(WebViewContainer.this, container);
                }

                @Override
                public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {

                }

                @Override
                public void notImplemented() {

                }
            });
            return true;
        }
    };
    WebViewClient webViewClient = new WebViewClient() {

        List<String> intercepts;
        List<String> getIntercepts() {
            if (intercepts == null) {
                intercepts = new ArrayList<>();
                intercepts.add("html");
                intercepts.add("htm");
                intercepts.add("php");
                intercepts.add("");
            }
            return intercepts;
        }

        @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
        @Nullable
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            WebResourceResponse response = replaceResource(request.getUrl().toString());
            if (response != null) return response;

            String ext = findExtension(request.getUrl());
            if (ext == null || getIntercepts().contains(ext)) {
                try {
                    HttpURLConnection connection = requestUrl(
                            request.getUrl().toString(),
                            request.getMethod(),
                            request.getRequestHeaders());
                    return loadResponse(connection);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            return super.shouldInterceptRequest(view, request);
        }

        @Nullable
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
            WebResourceResponse response = replaceResource(url);
            if (response != null) return response;

            String ext = findExtension(Uri.parse(url));
            if (ext == null || getIntercepts().contains(ext)) {
                try {
                    HttpURLConnection connection = requestUrl(url, "GET", null);
                    return loadResponse(connection);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            return super.shouldInterceptRequest(view, url);
        }

        WebResourceResponse loadResponse(HttpURLConnection connection) throws IOException {
            String type = connection.getHeaderField("content-type");
            if (type == null) {
                type = connection.getHeaderField("Content-Type");
            }
//            Log.i("loadResponse", connection.getURL() + " : " + type);
            String url = connection.getURL().toString();
            int statusCode = connection.getResponseCode();
            String encoding = connection.getContentEncoding();
            if (encoding == null && type != null) {
                String[] values = type.split(";");
                for (String value : values) {
                    value = value.trim();

                    if (value.toLowerCase().startsWith("charset=")) {
                        encoding = value.substring("charset=".length());
                    }
                }
            }
            if (encoding == null) {
                encoding = "UTF-8";
            }
            if (type == null || statusCode >= 300) return null;
            if (type.toLowerCase().contains("text/html")) {
                InputStream stream = connection.getInputStream();
                BufferedReader reader = new BufferedReader(new InputStreamReader(stream, encoding));
                StringBuilder stringBuilder = new StringBuilder();
                char[] buf = new char[1024];
                int readed;
                while ((readed = reader.read(buf)) >= 0) {
                    if (readed > 0) {
                        stringBuilder.append(buf, 0, readed);
                    }
                }
                stream.close();
                reader.close();

                String raw = stringBuilder.toString();
                if (!raw.trim().startsWith("<!DOCTYPE html>")) return null;
                Document doc = Jsoup.parse(raw);
                {
                    List<Element> scripts = new ArrayList<>();
                    for (String script: beginScripts) {
                        Element e = new Element("script");
                        e.append(script);
                        scripts.add(e);
                    }
                    doc.head().insertChildren(0, scripts);
                }
                {
                    List<Element> scripts = new ArrayList<>();
                    for (String script: endScripts) {
                        Element e = new Element("script");
                        e.append(script);
                        scripts.add(e);
                    }
                    doc.body().appendChildren(scripts);
                }
                Map<String, String> headers = new HashMap<>();
                Map<String, List<String>> resHeaders = connection.getHeaderFields();
                for (String key: resHeaders.keySet()) {
                    List<String> res = resHeaders.get(key);
                    if (res.size() > 1) {
                        Log.w("WebViewContainer", "There are " + res.size() + " same header (" + key + ").");
                    }
                    if (key != null && key.toLowerCase().equals("set-cookie")) {
                        CookieManager cookieManager = CookieManager.getInstance();
                        cookieManager.setAcceptCookie(true);
                        CookieSyncManager cookieSyncManager = CookieSyncManager.getInstance();
                        for (String cookie: res) {
                            Log.i("WebViewContainer", "Set cookies " + url + " : " + cookie);
                            cookieManager.setCookie(connection.getURL().toString(), cookie);
                        }
                        cookieSyncManager.sync();
                        continue;
                    }
                    headers.put(key, StringUtil.join(res, ";"));
                }
                String html = doc.outerHtml();
                byte[] bytes = html.getBytes(encoding);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    return new WebResourceResponse(
                            "text/html",
                            encoding,
                            statusCode,
                            "OK",
                            headers,
                            new ByteArrayInputStream(bytes)
                    );
                } else {
                    return new WebResourceResponse(
                            "text/html",
                            encoding,
                            new ByteArrayInputStream(bytes)
                    );
                }
            }
            return null;
        }


        WebResourceResponse replaceResource(String url) {
            for (ResourceReplacement replacement : resourceReplacements) {
                Matcher matcher = replacement.test.matcher(url);
                if (matcher.find()) {
                    String mimeType = replacement.mimeType;
                    if (mimeType == null) {
                        ContentResolver cR = context.getContentResolver();
                        MimeTypeMap mime = MimeTypeMap.getSingleton();
                        Uri uri = Uri.parse(url);
                        mimeType = mime.getExtensionFromMimeType(cR.getType(uri));
                    }

                    try {
                        ByteArrayInputStream inputStream = new ByteArrayInputStream(replacement.resource.getBytes("UTF-8"));
                        return new WebResourceResponse(
                            mimeType,
                            "UTF-8",
                            inputStream
                        );
                    } catch (UnsupportedEncodingException e) {
                    }
                }
            }
            return null;
        }

        @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            String ext = findExtension(request.getUrl());
            if (downloadDetector.contains(ext)) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", id);
                map.put("url", request.getUrl().toString());
                map.put("method", "GET");
                map.put("headers", new HashMap<>());
                channel.invokeMethod("onDownload", map);
                return true;
            }
            return super.shouldOverrideUrlLoading(view, request);
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            String ext = findExtension(Uri.parse(url));
            if (downloadDetector.contains(ext)) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", id);
                map.put("url", url);
                map.put("method", "GET");
                map.put("headers", new HashMap<>());
                channel.invokeMethod("onDownload", map);
                return true;
            }
            return super.shouldOverrideUrlLoading(view, url);
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", webView.getUrl());
            channel.invokeMethod("loadStart", map);
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", webView.getUrl());
            channel.invokeMethod("loadEnd", map);
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", webView.getUrl());
            map.put("error", description);
            channel.invokeMethod("loadError", map);
        }

        @Override
        public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
            super.doUpdateVisitedHistory(view, url, isReload);
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", url);
            channel.invokeMethod("urlChanged", map);
        }

    };

    String findExtension(Uri uri) {
        List<String> segs = uri.getPathSegments();
        if (segs.size() > 0) {
            String seg = segs.get(segs.size() - 1);
            String ext = null;
            int idx = seg.lastIndexOf(".");
            if (idx >= 0) {
                ext = seg.substring(idx + 1);
            }
            return ext;
        }
        return null;
    }

    DownloadListener downloadListener = new DownloadListener() {
        @Override
        public void onDownloadStart(String url, String userAgent, String contentDisposition, String mimetype, long contentLength) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("url", url);
            map.put("filename", URLUtil.guessFileName(url, contentDisposition,
                    mimetype));
            channel.invokeMethod("onDownload", map);
        }
    };

    class Messenger {
        @JavascriptInterface
        public void postMessage(String event, String data) {
            onEvent(event, data);
        }
    }

    public WebView getWebView() {
        return webView;
    }

    List<String> downloadDetector = new ArrayList<>();
    void setDownloadDetector(List<String> list) {
        downloadDetector = list;
    }


    Handler handler;
    Map<String, Object> args;
    public WebViewContainer(@NonNull Context context, Map<String, Object> args, MethodChannel channel) {
        this.channel = channel;
        handler = new Handler();

        this.args = args;
        this.context = context;
        id = args.get("id");
        webView = new NeoWebView(context);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webView.setWebContentsDebuggingEnabled(true);
        }
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setMediaPlaybackRequiresUserGesture(false);
        webView.setWebChromeClient(webChromeClient);
        webView.setWebViewClient(webViewClient);
        webView.addJavascriptInterface(new Messenger(), "$messenger");
        webView.setDownloadListener(downloadListener);

        List<Object> scripts = (List<Object>)args.get("scripts");
        if (scripts != null) {
            for (Object item: scripts) {
                Map<Object, Object> itemMap = (Map<Object, Object>)item;
                String script = (String)itemMap.get("script");
                Number position = (Number)itemMap.get("position");
                Map<Object, Object> arguments = (Map<Object, Object>)itemMap.get("arguments");
                for (Object key :
                        arguments.keySet()) {
                    Object obj = arguments.get(key);
                    if ("POST_MESSAGE".equals(obj)) {
                        obj = "\\$messenger.postMessage(arguments[0], JSON.stringify(arguments[1]))";
                    }
                    script = script.replaceAll("\\{"+key+"\\}", obj + "");
                }
                if (position.intValue() == 0) {
                    beginScripts.add(script);
                } else {
                    endScripts.add(script);
                }
            }
        }
        List<Object> resourceReplacements = (List<Object>)args.get("resourceReplacements");
        if (resourceReplacements != null) {
            for (Object item : resourceReplacements) {
                Map<Object, Object> itemMap = (Map<Object, Object>)item;
                String test = (String)itemMap.get("test");
                String mimeType = (String)itemMap.get("mimeType");
                String resource = (String)itemMap.get("resource");

                ResourceReplacement replacement = new ResourceReplacement();
                replacement.test = Pattern.compile(test);
                replacement.mimeType = mimeType;
                replacement.resource = resource;

                this.resourceReplacements.add(replacement);
            }
        }
        String url = (String)args.get("url");
        if (url != null) {
            webView.loadUrl(url);
        }
    }

    public interface ITackCaptureCallback {
        void onComplete(String path);
        void onFailed(String msg);
    }
    public void takeCapture(final int width, final ITackCaptureCallback callback) {
        new Thread(new Runnable() {
            @Override
            public void run() {

                float scale = (float) width / webView.getMeasuredWidth();
                int height = (int) (webView.getMeasuredHeight() * scale);
                Bitmap bitmap = Bitmap.createBitmap(width,
                        height, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(bitmap);
                canvas.scale(scale, scale);
                canvas.translate(-webView.getScrollX(), -webView.getScrollY());
                webView.draw(canvas);

                FileOutputStream fos;
                try {
                    File file = getWebView().getContext().getCacheDir();
                    if (!file.exists()) {
                        file.mkdir();
                    }

                    final String path = file.getPath() + "/capture_" + Math.random() + "_" + new Date().getTime() + ".jpg";
                    fos = new FileOutputStream(path);
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, fos);

                    fos.close();
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            callback.onComplete(path);
                        }
                    });
                } catch (final Exception e) {
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            callback.onFailed(e.getMessage());
                        }
                    });
                } finally {
                    bitmap.recycle();
                }
            }
        }).start();
    }

    void onEvent(final String event, final Object data) {
        handler.post(new Runnable() {
            @Override
            public void run() {
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("id", id);
                arguments.put("event", event);
                arguments.put("json", data);
                channel.invokeMethod("onEvent", arguments);
            }
        });
    }

    HttpURLConnection requestUrl(String url, String method, Map<String, String> headers) throws Exception {
        HttpURLConnection connection = (HttpURLConnection)new URL(url).openConnection();
        connection.setRequestMethod(method);
        if (headers != null) {
            for (String key : headers.keySet()) {
                String value = headers.get(key);
                connection.addRequestProperty(key, value.toString());
            }
        }
        CookieManager cookieManager = CookieManager.getInstance();
        connection.addRequestProperty("cookie", cookieManager.getCookie(url));
        return connection;
    }

    public void makeOffScreen() {
        Activity activity = getActivity(context);
        ViewGroup contentView = (ViewGroup) activity.findViewById(android.R.id.content);
        ViewGroup mainView = (ViewGroup) (contentView).getChildAt(0);
        if (mainView != null) {
            View view = getWebView();
            view.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            mainView.addView(view, 0);
            view.setVisibility(View.INVISIBLE);
        }
    }

    public Activity getActivity(Context context)
    {
        if (context == null)
        {
            return null;
        }
        else if (context instanceof ContextWrapper)
        {
            if (context instanceof Activity)
            {
                return (Activity) context;
            }
            else
            {
                return getActivity(((ContextWrapper) context).getBaseContext());
            }
        }

        return null;
    }
}
