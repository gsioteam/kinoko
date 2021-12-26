package com.neo.browser_webview;

import android.content.Context;

import java.util.Map;

import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class BrowserWebViewFactory extends PlatformViewFactory {
    
    public interface IGetContainer {
        WebViewContainer find(Object id);
    }

    IGetContainer containerStore;

    public BrowserWebViewFactory(IGetContainer containerStore) {
        super(StandardMessageCodec.INSTANCE);
        this.containerStore = containerStore;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        Map map = (Map)args;
        return new BrowserWebView(containerStore.find(map.get("id")));
    }
}
