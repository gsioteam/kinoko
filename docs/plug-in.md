# How to write a Plug-in

Plug-in is the manga resource provider. You can write 
a plug-in with `javascript` or `ruby`.

### Configure file

There must be a `config.json` at the plug-in root directory.
All most all the plug-in information is recorded in the
configuration file.

```json
{
    // @require The name of plug-in
    "name": "DM5",
    // @option If icon is not specified, application 
    // will try to load the `/icon.png` as icon.
    "icon": "https://css99tel.cdndm5.com/v202008141414/dm5/images/header-logo.png",
    // @option The home page of target web site.
    "url": "https://www.dm5.cn/",
    // @require The index script, The script will be 
    // used in home page.
    "index": "index.rb",
    // @require In this application(Kinoko), collections
    // must have two file.
    // The first is the book script. To load information
    // Of a book include chapter information. And they
    // will be displayed on the book page.
    // The secound is the chapter script. To load 
    // the pitures of this chapter.
    "collections": [
        "book.rb",
        "chapter.rb"
    ],
    // @option The search script.
    // If `search` is specified, a search button will
    // be shown on right top of the home page.
    "search": {
        "src": "search.rb",
        // @option Search data. This will be the pass
        // the search initializer as a argument.
        "data": {
            "url": "https://m.dm5.com/search?title={0}&language=1&page={1}"
        }
    },
    // @option The settings script.
    // If `settings` is specified, a settings button
    // will be shown on right top of the home page.
    "settings": "settings.rb",
    // @require The categories data.
    // If the length categories is greater than 1,
    // A tabBar will be displayed on home page,
    // to select a category to display.
    // And each category data will be pass to
    // the `index` initializer as a arguments.
    "categories": [
        {
            "title": "Update",
            "id": "update",
            "url": "https://m.dm5.com/"
        },
    ]
}
```

### Native Classes

You can find many classes which is not implemented in 
the script layer. Because they are implemented in cpp
code. I bind it via class name, so you can search the 
cpp code via class name.

Such as:

```js
// Collection is bound to cpp class gs::Collection.
Collection.class_name = 'gs::Collection';
Collection.reg();

// Request is bound to cpp class gs::Request.
Request.class_name = 'gs::Request';
Request.reg();
```

### class:Collection 

All most all the script must return a subclass of
`Collection` class. The `Collection` own life cycle
and the interface to receive the provided data.

```js
class Collection {

    /**
     * The initialize argument is different depending
     * on the script type.
     * 
     * For `index`, data is the category data.
     * For `book`, data is the book data(DataItem)
     * For `chapter`, data is the chapter data(DataItem)
     * For `search`, data is the search data from config.json
     */
    constructor(data);

    /**
     * @need override
     * Load the data of the first page. This function
     * will be invoked on many situation. such as 
     * first view, data expires or reload action.
     * 
     * @param {String}data.key only appear in `search`
     * the keyword for searching.
     * 
     * @param {number}data.page may nerver appear. In my 
     * design I can jump to any page via this 
     * argument but at last I have not implemented
     * this.
     * 
     * @param {Callback}cb A callback invoke it when 
     * load complete or error occurred.
     * cb.apply(null) for loading complete.
     * cb.apply(err) for an error occurred.
     * 
     * Before the loading complete. You have to 
     * fill in the data with `setDataAt`, `setData`
     * or `appendData`.
     * 
     * @return {bool} if false means, I don`t load
     * any thing. default is false. 
     * 
     */
    reload(data, cb);

    /**
     * @need override
     * To load the data of next page.
     * 
     * @param {Callback}cb same as `reload`
     * 
     */
    loadMore(cb);

    /**
     * Set the value to the index position.
     * Do not need to worry about the data size,
     * This function would resize the data if 
     * necessary.
     */
    setDataAt(value, index)

    /**
     * Set all data
     * 
     * @param {Array}data
     */
    setData(data)

    /**
     * Append data at the end.
     * 
     * @param {Array}data
     */
    appendData(data)

    /**
     * The value of `info_data` field is same as 
     * the first argument of initializer.
     */
    info_data

    /**
     * Get sand set setting value, also can be used for persistent 
     * data storage.
     * 
     * After set a setting value using synchronizeSettings() for 
     * save your changes.
     * 
     */
    getSetting(key)
    setSetting(key, value)
    synchronizeSettings()

    /**
     * @member {String}temp
     * The xml template file path, for customer UI.
     * see [package:xml_layout](https://pub.dev/packages/xml_layout)
     */
    temp

    /**
     * Get current language.
     */
    getLanguage()
}
```

### Run local plug-in

Enable debug mode for run the local plug-in.

1. Set `com.ero.kinoko.MainActivity.is_debug` to `true`.
2. Put your plugin to `android/app/src/main/assets/debug/project`

Then, just run the modified application on a device. The plug-in will 
be used for main plug-in, no matter what plug-in is selected.

