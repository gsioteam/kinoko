
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
    // require, The plug-in name
    "name": "Demo",
    // option, Thie plug-in icon
    "icon": "icon.png",
    // require, The entry point of plug-in
    "index": "index",
    // option, The elevation of AppBar
    "appbar_elevation": 0,
    // require, A logic script with out UI， which is used to perform special functions.
    "processor": "processor",
    // option, The icons will be displayed on the right of AppBar.
    // And navigate to the page write in index attribute by pressing
    // the icon.
    "extensions": [{
        "icon": "search",
        "index": "search"
    }]
}
```

```js
// processor.js
// Processor will be used in two satuations
//   1. Load the manga pictures.
//   2. Check if a manga has new chapter.  
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
     * @return Promise<Object> 
     *    {title, key} The information of last chapter 
     */
    checkNew();
}
module.exports = MangaProcesser;
```