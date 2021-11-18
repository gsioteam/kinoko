
class BookController extends Controller {
    async load(data) {
        this.data = {
            title: data.title,
            subtitle: data.subtitle,
            summary: data.summary,
            picture: data.picture,
            loading: false,
            editing: false,
            reverse: localStorage['reverse'] != 'false',
            list: []
        };
        this.selected = [];

        this.url = data.link;
        
        let cached = localStorage[`book:${this.url}`];
        if (cached) {
            let data = JSON.parse(cached);
            this.data.title = data.title;
            if (data.subtitle) this.data.subtitle = data.subtitle;
            if (data.summary) this.data.summary = data.summary;
            this.data.list = data.list;

            let now = new Date().getTime();
            if (now - (data.time || 0) > 30 * 60 * 1000) {
                this.reload();
            }
        } else {
            this.reload();
        }
    }

    unload() {

    }

    onRefresh() {
        this.reload();
    }

    async reload() {
        this.setState(()=>{
            this.data.loading = true;
        });
        try {
            let url = this.url + '?waring=1';
            let res = await fetch(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36',
                    'Accept-Language': 'en-US,en;q=0.9',
                }
            });
            let text = await res.text();
    
            let data = this.parseData(text);
    
            let now = new Date().getTime();
            data.time = now;
            localStorage[`book:${this.url}`] = JSON.stringify(data);
    
            this.setState(()=>{
                this.data.title = data.title;
                if (data.subtitle) this.data.subtitle = data.subtitle;
                if (data.summary) this.data.summary = data.summary;
                this.data.list = data.list;
                this.data.loading = false;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    parseData(text) {
        const doc = HTMLParser.parse(text);
        let h1 = doc.querySelector(".book-info h1");
        let title = h1.text.trim();
        
        let infos = doc.querySelectorAll(".short-info p");
        let subtitle, summary;

        if (infos.length >= 2) {
            subtitle = infos[0].text;
        }
        if (infos.length >= 1) {
            summary = infos[infos.length - 1].text.trim().replace(/^Summary\:/, '').trim();
        }

        let list = [];
        let nodes = doc.querySelectorAll('.chapter-box > li');
        for (let node of nodes) {
            let anode = node.querySelector('div.chapter-name.long a');
            let name = anode.text.trim();
            list.push({
                title: name.replace(/new$/, ''),
                subtitle: name.match(/new$/)?'new':null,
                link: anode.getAttribute('href'),
            });
        }
        return {
            title: title,
            subtitle: subtitle,
            summary: summary,
            list: list.reverse(),
        };
    }

    onFavoritePressed() {

    }

    onDownloadPressed() {
        this.setState(()=>{
            this.data.editing = true;
        });
    }

    onClearPressed() {
        this.selected = [];
        this.setState(()=>{
            this.data.editing = false;
        });
    }
    
    onCheckPressed() {
        let downloads = [];
        for (let idx of this.selected) {
            var data = this.data.list[idx];
            downloads.push({
                key: data.link,
                title: this.data.title,
                link: this.url,
                picture: this.data.picture,
                subtitle: this.data.subtitle,
                data: data,
            });
        }
        this.addDownload(downloads);

        this.selected = [];
        this.setState(()=>{
            this.data.editing = false;
        });
    }

    onPressed(idx) {
        if (this.data.editing) {
            this.setState(()=>{
                let loc = this.selected.indexOf(idx);
                if (loc >= 0) {
                    this.selected.splice(loc, 1);
                } else {
                    this.selected.push(idx);
                }
            });
        } else {
            this.openBook({
                list: this.data.list,
                index: idx,
            });
        }
    }

    isSelected(index) {
        return this.selected.indexOf(index) >= 0;
    }

    onSourcePressed() {
        this.openBrowser(this.url);
    }

    onOrderSelected(value) {
        this.setState(()=>{
            this.data.reverse = value;
            localStorage['reverse'] = value.toString();
        });
    }

    isDownloaded(index) {
        let item = this.data.list[index];
        return DownloadManager.exist(item.link);
    }
}

module.exports = BookController;