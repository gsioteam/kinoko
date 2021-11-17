
const _timers = {};
let _timerId = 0;
globalThis.setTimeout = function (func, time) {
    let id = _timerId++;
    let timer = new Timer(time, false);
    _timers[id] = timer;
    timer.onTimeout = function() {
        delete _timers[id];
        func();
    };
    timer.start();
    return id;
}

globalThis.setInterval = function (func, time) {
    let id = _timerId++;
    let timer = new Timer(time, true);
    _timers[id] = timer;
    timer.onTimeout = function() {
        delete _timers[id];
        func();
    };
    timer.start();
    return id;
}

globalThis.clearInterval = globalThis.clearTimeout = function (id) {
    var timer = _timers[id];
    if (timer) {
        timer.stop();
        delete _timers[id];
    }
} 