
class URL {
    constructor(url) {
        let str = url;
        let potocal_reg = str.match(/^\w+:/);
        if (!potocal_reg) {
            return;
        } 
        this.protocol = potocal_reg[0];
        str = str.substr(this.protocol.length + 2);
        this.host = this.hostname = str.substr(0, str.indexOf('/'));
        str = str.substr(this.host.length);
        let path = str;
        let sidx = path.indexOf('?');
        this.path = path.substr(0, sidx);
        if (!this.path) this.path = "/";
        let search = path.substr(sidx);
        let hidx = search.indexOf('#');
        this.search = search.substr(0, hidx);
        this.hash = search.substr(hidx);
        this.origin = this.protocol + '//' + this.hostname;
        this.href = this.origin + this.path + this.search + this.hash;
    }
}

class PageURL {
    constructor(url) {
        this.url = new URL(url);
    }

    href(src) {
        if (src.match(/^\w+:/)) {
            return src;
        } else if (src[0] === '/') {
            return this.url.origin + src;
        } else {
            let bsegs = this.url.pathname.split('/');
            let segs = src.split('/');
            for (let seg of segs) {
                if (seg === '.') {

                } else if (seg === '..') {
                    bsegs.pop();
                } else {
                    bsegs.push(seg);
                }
            }
            let path = bsegs.join('/');
            if (path[0] !== '/') {
                path = '/' + path;
            }
            return this.url.origin + path;
        }
    }
}

module.exports = PageURL;