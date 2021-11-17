
require('./http_request')

class Request {
    constructor(resource, init) {
        init = init || {}
        this.method = init.method;
        this.headers = init.headers;
        this.body = init.body;
        this.mode = init.mode;
        this.credentials = init.credentials;
        this.cache = init.cache;
        this.redirect = init.redirect;
        this.referrer = init.referrer;
        this.integrity = init.integrity;
        if (typeof resource == 'string') {
            this.url = resource;
        } else if (resource instanceof Request) {
            if (!this.url) this.url = resource.url;
            if (!this.method) this.method = resource.method;
            if (!this.headers) this.headers = resource.headers;
            if (!this.body) this.body = resource.body;
            if (!this.mode) this.mode = resource.mode;
            if (!this.credentials) this.credentials = resource.credentials;
            if (!this.cache) this.cache = resource.cache;
            if (!this.redirect) this.redirect = resource.redirect;
            if (!this.referrer) this.referrer = resource.referrer;
            if (!this.integrity) this.integrity = resource.integrity;
        }
    }

    _getResponse() {
        if (!this._response) {
            this._response = new Promise((resolve, reject)=>{
                let req = new XMLHttpRequest();
                req.open(this.method || 'GET', this.url);
                req.responseType = 'arraybuffer';
                if (this.headers) {
                    for (var key in this.headers) {
                        req.setRequestHeader(key, this.headers[key]);
                    }
                }
                let resolved = false;
                req.onreadystatechange = function() {
                    if (req.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
                        console.log("Resolve");
                        resolved = true;
                        resolve(new Response(req));
                    }
                };
                req.onerror = function(ev) {
                    if (!resolved) {
                        reject(new Error(ev.error));
                    }
                };
                req.send(this.body);
            });
        } 
        return this._response;
    }
    clone() {
        return new Request(this);
    }

    async arrayBuffer() {
        let res = await this._getResponse();
        return res.arrayBuffer();
    }

    async json() {
        let res = await this._getResponse();
        return res.json();
    }

    async text() {
        let res = await this._getResponse();
        return res.text();
    }
}

class Response {
    constructor(request) {
        this._request = request;
    }

    get status() {
        return this._request.status;
    }

    get ok() {
        return this.status >= 200 && this.status < 300;
    }

    get url() {
        return this._request.responseURL;
    }

    // TODO parse Headers
    get headers() {
        return this._request.getAllResponseHeaders();
    }

    _getBody() {
        if (!this._body) {
            this._body = new Promise((resolve, reject) => {
                if (this._request.readyState == XMLHttpRequest.DONE) {
                    resolve(this._request.response);
                    return;
                }
                let resolved = false;
                this._request.onload = function() {
                    resolve(this._request.response);
                };
                this._request.onerror = function(ev) {
                    if (!resolved) {
                        reject(new Error(ev.error));
                    }
                };
            });
        }
        return this._body;
    }

    arrayBuffer() {
        return this._getBody();
    }

    clone() {
        return new Response(this._request);
    }

    async json() {
        let buf = Buffer.from(await this._getBody());
        return JSON.parse(buf.toString('utf-8'));
    }

    async text() {
        let buf = Buffer.from(await this._getBody());
        return buf.toString('utf-8');
    }
}

function fetch(resource, init) {
    let request = new Request(resource, init);
    return request._getResponse();
}

globalThis.Request = Request;
globalThis.Response = Response;
globalThis.fetch = fetch;