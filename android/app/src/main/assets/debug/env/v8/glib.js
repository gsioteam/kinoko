const Object = require('./object');

class Callback extends Object {

    static fromFunction(func) {
        let cb = FunctionCallback.new();
        cb.func = func;
        return cb;
    }

    apply() {
        let argv = [];
        for (let i = 0; i < arguments.length; i++) {
            argv.push(arguments[i]);
        }
        this.invoke(argv);
    }

    toObject() {
        if (this.func) return this.func;
        else {
            const that = this;
            return function(d) {
                return that.apply(...arguments);
            };
        }
    }
}

Callback.class_name = 'gc::_Callback';
Callback.reg();

class FunctionCallback extends Callback {
    _invoke(argv) {
        if (this.func) {
            let arr = [];
            for (let i = 0; i < argv.length; i++) {
                arr.push(argv.get(i));
            }
            let ret;
            try {
                ret = this.func.apply(this, arr);
            } catch (e) {
                console.log('error in Function Callback ' + e.message + '\n' + e.stack);
            }
            return ret;
        } else {
            throw new Error("No function set!");
        }
    }
}

class Array extends Object {

    fill(arr) {
        this.resize(arr.length);
        for (let i = 0, t = arr.length; i < t; ++i) {
            this.set(i, arr[i]);
        }
    }

    toArray() {
        return toObject(this);
    }

    get length() {
        return this.size();
    }

    set length(v) {
        this.resize(arr.length);
    }

    push(obj) {
        this.push_back(obj);
    }
}
Array.class_name = 'gc::_Array';
Array.reg();

class Map extends Object {

    toObject() {
        return toObject(this);
    }
}
Map.class_name = 'gc::_Map';
Map.reg();

class Data extends Object {

    toString(code) {
        if (code) {
            return Encoder.decode(this, code);
        } else {
            return this.text();
        }
    }
}

Data.class_name = 'gc::Data';
Data.reg();

class FileData extends Object {
    toString(code) {
        if (code) {
            return Encoder.decode(this, code);
        } else {
            return this.text();
        }
    }
}
FileData.class_name = 'gc::FileData';
FileData.reg();

class Request extends Object {
}
Request.class_name = 'gs::Request';
Request.reg();
Request.BodyType = {
    Raw: 0,
    Mutilpart: 1,
    UrlEncode: 2
};

class Collection extends Object {
    get settings() {
        let collection = this;
        return {
            set(key, value) {
                collection.setSetting(key, value);
            },
            get(key) {
                return collection.getSetting(key);
            },
            save() {
                collection.synchronizeSettings();
            }
        };
    }
}
Collection.class_name = 'gs::Collection';
Collection.reg();

class Encoder extends Object {
}
Encoder.class_name = 'gs::Encoder';
Encoder.reg();

function toObject(obj) {
    if (obj instanceof Map) {
        let ret = {};
        let keys = obj.keys();
        for (let i = 0, t = keys.length; i < t; ++i) {
            let key = keys.get(i);
            ret[key] = toObject(obj.get(key));
        }
        return ret;
    } else if (obj instanceof Array) {
        let arr = [];
        for (let i = 0, t = obj.length; i < t; ++i) {
            arr.push(toObject(obj.get(i)));
        }
        return arr;
    } else if (obj instanceof Callback) {
        return obj.toObject();
    } else {
        return obj;
    }
}

class GumboNode extends Object {

    
    querySelector(selector) {
        let arr = this.query(selector);
        return arr.length > 0 ? arr.get(0) : null;
    }

    querySelectorAll(selector) {
        return this.query(selector).toArray();
    }

    get text() {
        return this.getText();
    }
    
    get tagName() {
        return this.getTagName();
    }

    get parentElement() {
        return this.parent();
    }

    get parentNode() {
        return this.parent();
    }

    get children() {
        if (!this._children) {
            this._children = [];
            for (let i = 0, t = this.childCount(); i < t; ++i) {
                this._children.push(this.childAt(i));
            }
        }
        return this._children;
    }

    get type() {
        return this.getType();
    }
    
    attr(name) {
        return this.getAttribute(name)
    }
}
GumboNode.class_name = 'gs::GumboNode';
GumboNode.reg();
GumboNode.Type = {
    Document: 0,
    Element: 1,
    Text: 2,
    CData: 3,
    Comment: 4,
    WhiteSpace: 5,
    Template: 6
};

class DataItem extends Object {
}
DataItem.class_name = 'gs::DataItem';
DataItem.reg();
DataItem.Type = {
    Data: 0,
    Header: 1
};

class Error extends Object {
}
Error.class_name = 'gs::Error';
Error.reg();

class ScriptContext extends Object {
}
ScriptContext.class_name = 'gs::ScriptContext';
ScriptContext.reg();

class SettingItem extends Object {}
SettingItem.class_name = 'gs::SettingItem';
SettingItem.reg();
SettingItem.Type = {
    Header: 0,
    Switch: 1,
    Input: 2,
    Options: 3
};

class Platform extends Object {
}
Platform.class_name = 'gs::Platform';
Platform.reg();

class Browser extends Object {
}
Browser.class_name = 'gs::Browser';
Browser.reg();

class KeyValue extends Object {
}
KeyValue.class_name = 'gs::KeyValue';
KeyValue.reg();

module.exports = {
    Object,
    Callback,
    Array,
    Map,
    Data,
    FileData,
    
    Request,
    Collection,
    GumboNode,
    DataItem,
    Error,
    ScriptContext,
    Encoder,
    SettingItem,
    Platform,
    Browser,
    KeyValue,
};
