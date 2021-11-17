
require('./url');
require('./set_timeout');
globalThis.Buffer = require('buffer').Buffer;

globalThis.atob = (str) => Buffer.from(str, 'base64').toString('utf-8');
globalThis.btoa = (str) => Buffer.from(str).toString('base64');

const OriginEventTarget = require('event-target-shim').EventTarget;
const Event = require('event-target-shim').Event;
class EventTarget extends OriginEventTarget {
    dispatchEvent(event) {
        let type = event.type;
        let func = this['on' + type.toLowerCase()];
        if (typeof func == 'function') {
            func.call(this, event);
        }
        super.dispatchEvent(...arguments);
    }
}
globalThis.Event = Event;
globalThis.EventTarget = EventTarget;