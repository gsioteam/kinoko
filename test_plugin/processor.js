

class MangaProcesser extends Processor {

    // The key for cache data
    get key() {
        return this.data.link;
    }

    // Start load pictures
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
                console.log(`options count ${options.length}`);
                for (let i = 0, t = options.length; i < t; i++) {
                    urls.push(root_url.replace(/(-\d+)*\.html$/i, `-10-${i+1}.html`));
                }
                state = {
                    offset: 0,
                    index: 0,
                    urls: urls,
                }
            }

            while (state.index < state.urls.length) {
                this.save(false, state);
                let url = state.urls[state.index];
                let doc = await this.fetch(url);
                if (this.disposed) return;
                state.offset = this.parseDoc(doc, root_url, state.offset);
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

    parseDoc(doc, root_url, offset) {
        let imgs = doc.querySelectorAll('.pic_box > img');
        console.log(`imgs ${imgs.length}`);
        for (let i = 0, t = imgs.length; i < t; ++i) {
            let img = imgs[i];
            let index = offset + i;
            this.setDataAt({
                url: img.getAttribute('src'),
            }, index);
        }
        return offset + imgs.length;
    }

    // Called in `dispose`
    unload() {

    }
}

module.exports = MangaProcesser;