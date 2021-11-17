const url = require('url');
const Url = url.Url;

class URL {
    constructor(relative, base) {
        if (base) {
            this._url = url.parse(url.resolve(base, relative));
        } else {
            this._url = url.parse(relative);
        }
    }

    get auth() {
        return this._url.auth;
    }
    set auth(v) {
        this._url.auth = v;
    }

    get hash() {
        return this._url.hash;
    }
    set hash(v) {
        this._url.hash = v;
    }

    get host() {
        return this._url.host;
    }
    set host(v) {
        this._url.host = v;
    }

    get hostname() {
        return this._url.hostname;
    }
    set hostname(v) {
        this._url.hostname = v;
    }

    get href() {
        return this._url.href;
    }
    set href(v) {
        this._url.href = v;
    }

    get path() {
        return this._url.path;
    }
    set path(v) {
        this._url.path = v;
    }

    get pathname() {
        return this._url.pathname;
    }
    set pathname(v) {
        this._url.pathname = v;
    }

    get protocol() {
        return this._url.protocol;
    }
    set protocol(v) {
        this._url.protocol = v;
    }

    get search() {
        return this._url.search;
    }
    set search(v) {
        this._url.search = v;
    }

    get slashes() {
        return this._url.slashes;
    }
    set slashes(v) {
        this._url.slashes = v;
    }

    get port() {
        return this._url.port;
    }
    set port(v) {
        this._url.port = v;
    }

    get query() {
        return this._url.query;
    }
    set query(v) {
        this._url.query = v;
    }

    toString() {
        return this._url.format();
    }
}

globalThis.URL = URL;
