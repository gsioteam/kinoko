
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

const iconv = require('xprezzo-iconv');

class TextDecoder {
    constructor(encoding) {
        this._encoding = encoding ?? 'utf-8';
    }

    get encoding() {
        return this._encoding;
    }

    decode(buf) {
        return iconv.decode(Buffer.from(buf), this.encoding);
    }
}

class TextEncoder {
    
    get encoding() {
        return "utf-8";
    }

    encode(text) {
        return iconv.encode(text, this.encoding);
    }

    encodeInto(text, array) {
        let buf = this.encode(text);
        let ret = {
            read: text.length,
            written: buf.length,
        };
        if (buf.length > array.length) {
            ret.read = parseInt(array.length / buf.length * ret.read);
            ret.written = array.length;
        }
        array.set(buf, 0);
        return ret;
    }
}

globalThis.TextDecoder = TextDecoder;
globalThis.TextEncoder = TextEncoder;