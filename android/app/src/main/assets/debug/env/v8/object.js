let cache = [];

class Object {

    static reg() {
        _registerClass(this, this.class_name);   
    }

    static new() {
        let argv = [];
        for (let i = 0, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }
        let obj = new (Function.prototype.bind.apply(this, [null].concat(argv)));
        _newObject(obj, this.class_name, argv);
        obj.initialize.apply(obj, argv);

        return obj;
    }

    destory() {
        _destroyObject(this);
    }

    _call(name) {
        let argv = [];
        for (let i = 1, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }
        return _call.apply(this, [name, argv]);
    }

    static _call(name) {
        let argv = [];
        for (let i = 1, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }
        return _callStatic.apply(this, [name, argv]);
    }

    _keep() {
        let idx = cache.indexOf(this);
        if (idx < 0) {
            cache.push(this);
        }
    }

    _release() {
        let idx = cache.indexOf(this);
        if (idx >= 0) {
            cache.splice(idx, 1);
        }
    }

    initialize() {}
}

Object.class_name = 'gc::Object';
Object.reg();

module.exports = Object;
