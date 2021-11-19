const bookFetch = require('./book_fetch');

/**
 * @property {String}key need override the key for caching
 * @method load need override,
 * @method checkNew need override
 */
class MangaProcesser extends Processor {

    // The key for caching data
    get key() {
        return this.data.link;
    }

    /**
     * 
     * Start load pictures
     * 
     * @param {*} state The saved state.
     */
    async load(state) {
        try {
            let root_url = this.data.link;
            this.loading = true;
            if (state && state.urls) {
            } else {
                let url = root_url.replace(/(-\d+)*\.html$/i, '-10-1.html');
                let doc = await this.fetch(url);

                let select = doc.querySelector('select.sl-page');
                let options = select.querySelectorAll('option');
                let urls = [];
                for (let i = 0, t = options.length; i < t; i++) {
                    urls.push(root_url.replace(/(-\d+)*\.html$/i, `-10-${i+1}.html`));
                }
                state = {
                    offset: 0,
                    index: 0,
                    urls: urls,
                }
            }

            const that = this;
            function parseDoc(doc, root_url, offset) {
                let imgs = doc.querySelectorAll('.pic_box > img');
                for (let i = 0, t = imgs.length; i < t; ++i) {
                    let img = imgs[i];
                    let index = offset + i;
                    /**
                     * @property {String} url The picture url.
                     * @property {Object*} headers The picture headers.
                     */
                    that.setDataAt({
                        url: img.getAttribute('src'),
                    }, index);
                }
                return offset + imgs.length;
            }

            while (state.index < state.urls.length) {
                // Save the current state
                this.save(false, state);
                let url = state.urls[state.index];
                let doc = await this.fetch(url);
                if (this.disposed) return;
                state.offset = parseDoc(doc, root_url, state.offset);
                state.index++;
            }
            this.save(true, state);
            this.loading = false;
        } catch (e) {
            console.log(`err ${e}\n${e.stack}`);
            this.loading = false;
        }
    }

    async fetch(url) {
        console.log(`request ${url}`);
        let res = await fetch(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            }
        });
        let text = await res.text();
        return HTMLParser.parse(text);
    }

    // Called in `dispose`
    unload() {

    }

    // Check for new chapter
    async checkNew() {
        let url = this.data.link + '?waring=1';
        let data = await bookFetch(url);
        var item = data.list[data.list.length - 1];
        /**
         * @property {String}title The last chapter title.
         * @property {String}key The unique identifier of last chpater.
         */
        return {
            title: item.title,
            key: item.link,
        };
    }
}

module.exports = MangaProcesser;