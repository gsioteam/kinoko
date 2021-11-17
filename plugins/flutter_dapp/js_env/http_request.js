

class ProgressEvent extends Event {
    constructor(type, options) {
        super(type, options);
        this.loaded = options.loaded;
        this.total = options.total;
    }
}

const Request = globalThis.Request;
class XMLHttpRequest extends EventTarget {
    constructor() {
        super();
        this._request = new Request();
        this._request.onState = this._onState.bind(this);
        this._readyState = XMLHttpRequest.UNSENT;
        this.responseType = '';
    }

    open(method, url) {
        this._request.open(method, url, {});
        this._readyState = XMLHttpRequest.OPENED;
        this.dispatchEvent(new Event('readystatechange'));
    }

    send(body) {
        this._request.send({
            type: typeof body,
            data: body
        });
    }

    abort() {
        this._request.abort();
    }

    setRequestHeader(key, value) {
        this._request.setRequestHeader(key, value);
    }

    getAllResponseHeaders() {
        return this._request.getAllResponseHeaders();
    }

    getResponseHeader(headerName) {
        if (headerName.toLowerCase() == 'content-type') 
            return this._overrideMimeType;
        return this._request.getResponseHeader(headerName);
    }

    overrideMimeType(mimeType) {
        this._overrideMimeType = mimeType;
    }

    _onState(type) {
        let event;
        switch (type) {
            case 'progress': {
                if (this._readyState != XMLHttpRequest.LOADING) {
                    this._readyState = XMLHttpRequest.LOADING;
                    this.dispatchEvent(new Event('readystatechange'));
                }
                event = new ProgressEvent(type, {
                    loaded: arguments[1],
                    total: arguments[2],
                });
                break;
            }
            case 'headers': {
                this._readyState = XMLHttpRequest.HEADERS_RECEIVED;
                this.dispatchEvent(new Event('readystatechange'));
                this._responseURL = arguments[1];
                return;
            }
            case 'loadend': {
                this._readyState = XMLHttpRequest.DONE;
                this.dispatchEvent(new Event('readystatechange'));
                event = new Event(type);
                break;
            }
            case 'error': {
                event = new Event(type);
                event.error = arguments[1];
                break;
            }
            default: {
                event = new Event(type);
                break;
            }
        }
        this.dispatchEvent(event);
    }

    set timeout(v) {
        this._request.timeout = v;
    }
    get timeout() {
        return this._request.timeout;
    }

    get readyState() {
        return this._readyState;
    }

    _getResponse() {
        if (!this._response) {
            this._response = this._request.response;
        }
        return this._response;
    }

    get response() {
        var res = this._getResponse();
        if (res) {
            switch (this.responseType) {
                case 'arraybuffer': {
                    return res;
                }
                case 'json': {
                    let buf = Buffer.from(res);
                    return JSON.parse(buf.toString('utf-8'));
                }
                case '':
                case 'text': {
                    let buf = Buffer.from(res);
                    return buf.toString('utf-8');
                }
            }
        }
    }

    get responseURL() {
        return this._responseURL;
    }
}

Object.defineProperties(XMLHttpRequest, {
    UNSENT: {
        get: () => 0
    },
    OPENED: {
        get: () => 1
    },
    HEADERS_RECEIVED: {
        get: () => 2,
    },
    LOADING: {
        get: () => 3,
    },
    DONE: {
        get: () => 4,
    }
});

globalThis.XMLHttpRequest = XMLHttpRequest;
globalThis.ProgressEvent = ProgressEvent;
globalThis.Buffer = Buffer;
