
global.console = {
    log() {
        _printInfo.apply(this, arguments);
    },
    warn() {
        _printWarn.apply(this, arguments);
    },
    error() {
        _printError.apply(this, arguments);
    }
};

global.glib = require('./glib');
let glib = global.glib;

let cbs = {};
global.setTimeout = function (fn, delay) {
    console.log('setTimeout  ' + delay);
    let cb, handle;
    cb = glib.Callback.fromFunction(function () {
        console.log('on timeout ');
        try {
            fn();
        } catch (e) {
            console.log(`${e.message}\n    ${e.stack}`);
        }
        delete cbs[handle];
    })
    handle = glib.Platform.startTimer(cb, delay / 1000.0, false);
    cbs[handle] = cb;
    return handle;
};

global.setInterval = function (fn, delay) {
    let cb, handle;
    cb = glib.Callback.fromFunction(fn)
    handle = glib.Platform.startTimer(cb, delay / 1000.0, true);
    cbs[handle] = cb;
    return handle;
}

global.clearTimeout = global.clearInterval = function (handle) {
    glib.Platform.cancelTimer(handle);
    delete cbs[handle];
}

const {PageURL, URL} = require('./page_url');
global.PageURL = PageURL;
global.URL = URL;