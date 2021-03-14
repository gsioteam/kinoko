package com.ero.kinoko;

import android.content.res.AssetManager;
import android.os.Bundle;
import android.view.KeyEvent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.qlp.glib.GlibPlugin;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    final boolean is_debug = false;
    private final String CHANNEL = "com.ero.kinoko/volume_button";
    boolean handleVolumeButton = false;
    MethodChannel channel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        if (is_debug) {
            File dir = getFilesDir();
            String path = dir.getPath() + "/debug";
            try {
                copyDir("debug", path);
            } catch (IOException e) {
                e.printStackTrace();
            }
            GlibPlugin.setDebug(path);
        }
        super.onCreate(savedInstanceState);
    }

    private void copyDir(String path, String targetPath) throws IOException {
        AssetManager manager = getAssets();
        String[] subpaths;
        try {
            subpaths = manager.list(path);
            if (subpaths != null && subpaths.length != 0) {
                for (String subpath : subpaths) {
                    if (subpath.length() > 0 && subpath.charAt(0) != '.') {
                        copyDir(path + "/" + subpath, targetPath + "/" + subpath);
                    }
                }
                return;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        final int bufLength = 2048;
        InputStream stream = manager.open(path);
        File file = new File(targetPath);
        File dir = file.getParentFile();
        if (!dir.exists()) dir.mkdirs();
        FileOutputStream outputStream = new FileOutputStream(file);
        byte[] buf = new byte[bufLength];
        int readed;
        while ((readed = stream.read(buf)) > 0) {
            outputStream.write(buf, 0, readed);
        }
        outputStream.close();
        stream.close();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
                if (call.method.equals("start")) {
                    handleVolumeButton = true;
                } else if (call.method.equals("stop")) {
                    handleVolumeButton = false;
                }
            }
        });
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (handleVolumeButton) {
            if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                int code = 0;
                if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                    code = 1;
                } else if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                    code = 2;
                }
                channel.invokeMethod("keyDown", code);
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }
}
