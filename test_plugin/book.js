
class BookController extends Controller {

    /**
     * 
     * @property {String}key The unique identifier of the favorite item
     * @property {String}title The name of book
     * @property {String}subtitle The subtitle of book
     * @property {String}picture The cover of book.
     * @property {Object}data Data will be sent to book page.
     * @property {String}page The book page path.
     */
    get bookInfo() {
        return {
            key: this.url,
            title: this.data.title,
            subtitle: this.data.subtitle,
            picture: this.data.picture,
            page: 'book',
            data: {
                link: this.url,
                title: this.data.title,
                subtitle: this.data.subtitle,
                picture: this.data.picture,
                summary: this.data.summary,
            },
        };
    }

    async load(data) {
        this.data = {
            title: data.title,
            subtitle: data.subtitle,
            summary: data.summary,
            picture: data.picture,
            loading: false,
            editing: false,
            reverse: localStorage['reverse'] != 'false',
            list: [],
            images: [],
        };
        this.selected = [];

        this.url = data.link;
        
        /**
         * Add history record
         * 
         * Same as addFavorite with out lastData.
         */
         this.addHistory(this.bookInfo);
        
        let cached = localStorage[`book:${this.url}`];
        if (cached) {
            let data = JSON.parse(cached);
            for (let key in data) {
                if (key == 'time') continue;
                this.data[key] = data[key];
            }

            let now = new Date().getTime();
            if (now - (data.time || 0) > 30 * 60 * 1000) {
                this.reload();
            }
        } else {
            this.reload();
        }
        FavoritesManager.clearNew(this.url);
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
            let res = await fetch(url);
            let text = await res.text();
            let data = this.parseData(text);
    
            let now = new Date().getTime();
            data.time = now;
            localStorage[`book:${this.url}`] = JSON.stringify(data);
    
            this.setState(()=>{
                for (let key in data) {
                    if (key == 'time') continue;
                    this.data[key] = data[key];
                }
                this.data.loading = false;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    parseData(text, url) {
        const doc = HTMLParser.parse(text);
        let imgs = doc.querySelectorAll("#thumbnail-container a.gallerythumb > img");
        let images = [];
        let item = {
            link: this.url + '/1'
        };
        for (let i = 0, t = imgs.length; i < t; i++) {
            let el = imgs[i];
            images.push(el.getAttribute('data-src'));
        }
        let picture = doc.querySelector('#cover img').getAttribute('data-src');
        let titles = doc.querySelectorAll('#info > .title');
        let title, subtitle;
        try {
            title = titles[0].text
            subtitle = titles[1].text;
        } catch (e) {
            
        }
        let tags = doc.querySelectorAll('#tags .tag-container:not(.hidden)');
        let dataTags = [];
        for (let i = 0, t = tags.length; i < t; ++i) {
            let tag = tags[i];
            let children = tag.childNodes;
            let title;
            for (let child of children) {
                if (child.nodeType == 3) {
                    let text = child.text.trim();
                    if (text.length > 0) {
                        title = text;
                        break;
                    }
                }
            }
            let links = [];
            let tagLinks = tag.querySelectorAll('.tags > a.tag');
            for (let link of tagLinks) {
                try {
                    let data = {
                        link: new URL(link.getAttribute('href'), url).toString(),
                        name: link.querySelector('.name').text,
                    };
                    let count = link.querySelector('.count');
                    if (count) data.count = count.text;
                    else data.count = '-'
                    links.push(data);
                } catch (e) {
                    console.log("Error : " + e.message);
                }
            }
            dataTags.push({
                title: title,
                links: links
            });
        }
    
        return {
            title: title,
            subtitle: subtitle,
            picture: picture,
            images: images,
            tags: dataTags,
            list: [item],
        };
    }

    onFavoritePressed() {
        this.setState(()=>{
            if (this.isFavarite()) {
                FavoritesManager.remove(this.url);
            } else {
                let last;
    
                /**
                 * Add to favorites list
                 * 
                 * The first argument see `bookinfo`
                 * 
                 * The second argument is optional
                 * @param {String}title The title of the last chapter
                 * @param {String}key The unique identifier of the last chapter
                 */
                if (this.data.list.length > 0) {
                    let data = this.data.list[this.data.list.length - 1];
                    last = {
                        title: data.title,
                        key: data.link,
                    };
                }
                this.addFavorite(this.bookInfo, last);
            }
        });
    }

    onDownloadPressed() {
        var data = this.data.list[0];
        this.addDownload([{
            key: data.link,
            title: this.data.title,
            link: this.url,
            picture: this.data.picture,
            subtitle: this.data.subtitle,
            data: data,
        }]);
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
            /**
             * Add to download queue
             * 
             * @param {String}key The unique identifier of the download item
             * @param {String}title The name of book
             * @param {String}subtitle The subtitle of book
             * @param {String}link The url of book, To group items with same book link.
             * @param {String}picture The cover of book.
             * @param {Object}data Data will be sent to processor load function.
             * @param {String*}data.title The title of chapter. 
             */
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

    // onPressed(idx) {
    //     if (this.data.editing) {
    //         this.setState(()=>{
    //             let loc = this.selected.indexOf(idx);
    //             if (loc >= 0) {
    //                 this.selected.splice(loc, 1);
    //             } else {
    //                 this.selected.push(idx);
    //             }
    //         });
    //     } else {
    //         this.openBook({
    //             list: this.data.list,
    //             index: idx,
    //         });
    //     }
    // }

    onImagePressed(idx) {
        this.openBook({
            list: this.data.list,
            index: 0,
            page: idx,
        });
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

    isFavarite() {
        return FavoritesManager.exist(this.url);
    }
}

module.exports = BookController;