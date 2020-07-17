let ClassCache  = {};

class Object {
    static class_name = 'gc::Object';

    static new() {
        let Cls = ClassCache[this.class_name];
        if (!Cls) {
            Cls = this;
            registerClass(Cls, this.class_name);
            ClassCache[this.class_name] = Cls;
        }

        let argv = [];
        for (let i = 0, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }

        let obj = new (Function.prototype.bind.apply(Cls, argv));
        newObject(obj, Cls, argv);
        obj.initialize();

        return obj;
    }

    initialize() {}
}

module.exports = Object;