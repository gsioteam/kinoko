package com.neo.browser_webview;

import android.view.View;

import java.util.Map;

import io.flutter.plugin.platform.PlatformView;

public class BrowserWebView implements PlatformView {

    Object id;
    WebViewContainer container;

    BrowserWebView(WebViewContainer container) {
        this.container = container;
    }

    @Override
    public View getView() {
        return container.getWebView();
    }

    @Override
    public void dispose() {

    }
}
