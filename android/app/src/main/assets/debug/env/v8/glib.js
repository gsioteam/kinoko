const Object = require('./object');

class Callback extends Object {
    static class_name = 'gc::_Callback';

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
}

Callback.reg();

class FunctionCallback extends Callback {
    _invoke(argv) {
        if (this.func) {
            let arr = [];
            for (let i = 0; i < argv.length; i++) {
                arr.push(argv.get(i));
            }
            var ret = this.func.apply(this, arr);
            return ret;
        } else {
            throw new Error("No function set!");
        }
    }
}

class Array extends Object {
    static class_name = 'gc::_Array';

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
Array.reg();

class Map extends Object {
    static class_name = 'gc::_Map';

    toObject() {
        return toObject(this);
    }
}
Map.reg();

class Data extends Object {
    static class_name = 'gc::Data';

    toString(code) {
        if (code) {
            return Encoder.decode(this, code);
        } else {
            return this.text();
        }
    }
}

Data.reg();

class Request extends Object {
    static class_name = 'gs::Request';
}
Request.reg();
Request.BodyType = {
    Raw: 0,
    Mutilpart: 1,
    UrlEncode: 2
};

class Collection extends Object {
    static class_name = 'gs::Collection';
}
Collection.reg();

class Encoder extends Object {
    static class_name = 'gs::Encoder';
}
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
    } else {
        return obj;
    }
}

class GumboNode extends Object {
    static class_name = 'gs::GumboNode';

    
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
    
    attr(name) {
        return this.getAttribute(name)
    }
}
GumboNode.reg();

class DataItem extends Object {
    static class_name = 'gs::DataItem';
}
DataItem.reg();
DataItem.Type = {
    Book: 0,
    Chapter: 1,
    Header: 2
};

class Error extends Object {
    static class_name = 'gs::Error';
}
Error.reg();

class ScriptContext extends Object {
    static class_name = 'gs::ScriptContext';
}
ScriptContext.reg();

module.exports = {
    Object,
    Callback,
    Array,
    Map,
    Data,
    
    Request,
    Collection,
    GumboNode,
    DataItem,
    Error,
    ScriptContext,
    Encoder,
};