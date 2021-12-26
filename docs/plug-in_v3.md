
## Why upgrading the plug-in system

The current plug-in system is complicated and incomprehensible. 
And interface template is also fragmented from the logic script. 
So I will implment a new plug-in system based on 
[flutter_dapp](https://github.com/gsioteam/flutter_dapp).

The new plug-in system is already be used in my another application 
[KumaV](https://github.com/gsioteam/KumaV), looks it works very well.

PS: The new plug-in system no longer support `ruby` script.

## Online Preview

This is a liveing [preview website](https://gsioteam.github.io/plugin_online/).

Try to input a plug-in git address likes:

- [https://github.com/gsioteam/plugin_demo.git](https://github.com/gsioteam/plugin_demo.git)
- [https://github.com/gsioteam/dramacool.git](https://github.com/gsioteam/dramacool.git)


## Description

V3 plug-in system is based on [flutter_dapp](https://github.com/gsioteam/flutter_dapp), it combine 
`xml_layout` and `js_script`. Through `flutter_dapp` you can write a new widget with a js file and
a xml template file.

For example:

index.js
```js
class IndexController extends Controller {
    // called in `initState()`
    load() {
        this.data = {
            tabs: [
                {
                    "title": "Users",
                    "id": "test",
                    "url": "https://reqres.in/api/users?page={0}"
                }, 
            ]
        };
    }

    // called in `dispose()`
    unload() {

    }
}

module.exports = IndexController;
```

index.xml
```xml
<tabs elevation="4" scrollable="true" background="hex(#fff)">
    <for array="$tabs">
        <tab title="${item.title}">
            <!-- Load another widget -->
            <widget src="main" data="$item"/>
        </tab>
    </for>
</tabs>
```

### config.json

```js
{
    // required, The plug-in name
    "name": "Demo",
    // optional, Thie plug-in icon
    "icon": "icon.png",
    // required, The entry point of plug-in
    "index": "index",
    // optional, The elevation of AppBar
    "appbar_elevation": 0,
    // required, A logic script with out UI， which is used to perform special functions.
    "processor": "processor",
    // optional, The icons will be displayed on the right of AppBar.
    // And navigate to the page write in index attribute by pressing
    // the icon.
    "extensions": [{
        "icon": "search",
        "index": "search"
    }]
}
```

### processor.js

```js
// processor.js
// Processor will be used in two satuations
//   1. Load manga pictures.
//   2. Detect if a manga has new chapter.  
class MangaProcesser extends Processor {
    // The unique identifier for detecting which manga chapter is processing on.
    get key();

    /**
     * Save the loading state, could be called in `load` method.
     *
     * @param {bool} complete, determie the loading complete or not.
     * @param {*} state, for `load` restart. 
     */
    save(complete, state);

    /**
     * Start load pictures, need override
     * 
     * @param {*} state The saved state.
     * @return Promise 
     */
    load(state);

     // Called in `dispose`, need override
    unload();

    /**
     * Check for new chapter, need override
     * 
     * @return Promise<{title, key}> The information of last chapter 
     */
    checkNew();

    /**
     * After getting the picture information, set the picture data than
     * it will be shown. 
     * @param data.url {String} The picture url
     * @param data.headers {Object} Optional, The picture http headers.
     * @param list {List} A list ot picture information.
     */ 
    setDataAt(data);
    setData(list);
}
module.exports = MangaProcesser;
```

## Built-in Functions

- `Controller` menber functions
    - `openBook(data)` Open the picture viewer page to view the specific manga.
        - `data.key` *String* The unique key of manga.
        - `data.list` *List* All the chapter data.
        - `data.index` *int* Current chapter index.
        - `data.page` *int* optional, Initial page number.
    - `openBrowser(url: String)` Open a webview page.
    - `addDownload(list)` Add to download list, and start download.
    - `addFavorite(data, last)` Add to favorite list.
        - `data` Information of the manga.
            - `data.page` *String* The template path of details page in plugin folder.
        - `last` Optional, Infomation of last chapter.
            - `last.key` *String* The unique key of last chapter.
            - `last.title` *String* The title of last chapter.
    - `addHistory(data)` Add to history list.
        - `data` Information of the manga.
            - `data.page` *String* The template path of details page in plugin folder.
    - `getLastKey(mangaKey)` Get the last key of manga
    - `setData(data)` 
- `DownloadManager` static functions
    - `DownloadManager.exist(chapterKey)` Return true when the chapter is already in download list, otherwise false.
    - `DownloadManager.removeKey(chapterKey)` Remove the chapter from the download list.
- `FavoritesManager` static functions
    - `FavoritesManager.exist(mangaKey)` Return true when the manga is already in favorite list, otherwise false.
    - `FavoritesManager.remove(mangaKey)` Remove the manga from the favorite list.
    - `FavoritesManager.clearNew(mangaKey)` Make as readed. Clear the red dot in favorites page.
- `NotificationCenter` static functions. A global notification center, the event can cross each js context, such as send event from `processor.js` to `main.js`.
    - `NotificationCenter.addObserver(event, func)` 
    - `NotificationCenter.removeObserver(event, func)`
    - `NotificationCenter.trigger(event, data)`
- `ScriptContext` Generate a new js context. `let ctx = new ScriptContext();`
    - `eval(script)` 
    - `postMessage(data)`
    - `onmessage` member field. Receive message from the js context.

## WebView

*v4.1.0* available.

- `HeadlessWebView`
    - `consturctor(options?)` 
        - `options.resourceReplacements` Replace the resource on the web site.
    - `load(url)` load web url.
    - `static getCookies(url)` Get cookies
    - `eval(script)` Eval script
    - `onmessage` Event, The callback from web site.
    - `onloadstart` The begin loading callback.
    - `onloadend` The end loading callback.
    - `onfail` The loading failed callback.
    
```js
// Hold the reference otherwise the webview will be released before loading complete.
this.webview = new HeadlessWebView({
    resourceReplacements: [{
        // `test` will be compile to a ExgEx.
        test:'jwplayer\.js',
        resource: this.loadString('my_jwplayer.js'),
        mimeType: 'text/javascript',
    }]
});
this.webview.onloadstart = (url) => {
    console.log(`[HeadlessWebView] loadStart ${url}`);
};
this.webview.onloadend = async (url) => {
    console.log(`[HeadlessWebView] loadEnd ${url}`);
    console.log(await this.webview.eval("document.querySelector('html').outerHTML"));
};
this.webview.onfail = (url, error) => {
    console.log(`[HeadlessWebView] loadFailed ${url} ${error}`);
};
/**
 * Invoke when the web site call `messenger.send('message', data)`
 */
this.webview.onmessage = (data) => {
    console.log(`[HeadlessWebView] onMessage ${data}`);
};
this.webview.load("https://www.google.com");
```
   
- `<webview />` A webview widget.
    - attributes:
        - `src` *String*, Initialize url
        - `onMessage` *void Function(data)* 
        - `onLoadStart` *void Function(url)*
        - `onLoadEnd` *void Function(url)*
        - `onFail` *void Function(url, error)*
        - `replacements` *List* same as `resourceReplacements` in `HeadlessWebView`
    - methods:
        - `eval(script)` return `Promise<*>`
        - `getCookies(url)` return `Promise<Object>`

```xml
<webview id="webview" src="https://www.google.com" onLoadEnd="loadEnd" />
```

```js
async loadEnd(url) {
    const webview = this.findElement('webview');
    console.log(`loadEnd ${url}`);
    console.log(await webview.eval("document.querySelector('html').outerHTML"));
    console.log(JSON.stringify(await webview.getCookies("https://www.google.com")));
}
```

## How to debug my local plugin?

1. Put your plugin files to `kinoko_path/test_plugin/`.

```
kinoko_path
└─── test_plugin
    ├── config.json
    ├── main.js
    └── ...
```

2. Find `kinoko_path/lib/configs.dart`, turn on the `isDebug` flag.

```dart
class Configs {

  // The plugin in `test_plugin` will be set as main plugin, when `isDebug` is true.
  static const bool isDebug = true;
  
  //...
}
```

Now, the your local plugin will be set as the main plugin.