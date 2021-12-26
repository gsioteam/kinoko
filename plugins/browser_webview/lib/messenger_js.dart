
const String js = """
window.messenger = {
    _l: {},
    send: function(event, data) {{on_send}},
    on: function(name, fn) {var arr = this._l[name] || [];arr.push(fn);this._l[name] = arr;},
    off: function(name, fn) {
        var arr = this._l[name];
        if (!arr) return;
        if (fn) {
            var i = arr.indexOf(fn);
            if (i > 0) arr.splice(i, 1);
        } else {
            delete this._l[name];
        }
    },
    _event: function(name, data) {
        var arr = this._l[name];
        if (arr) {
            var carr = arr.slice();
            for (var i = 0, t = carr.length; i < t; ++i) {
                carr[i](data);
            }
        }
    }
}
""";