package com.ero.kinoko;

import android.content.res.AssetManager;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.qlp.glib.GlibPlugin;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    final boolean is_debug = true;

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
        String[] subpaths = new String[0];
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
}
