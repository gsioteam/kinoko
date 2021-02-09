const {Collection} = require('./collection');

class BookCollection extends Collection {

    reload(data, cb) {
        let url = this.url + '?waring=1';
        console.log("Book url " + url);
        let purl = new PageURL(url);
        let info_data = this.info_data;
        this.fetch(url).then((doc) => {
            let h1 = doc.querySelector(".book-info h1");
            console.log("mark 1");
            info_data.title = h1.text.trim();
            let infos = doc.querySelectorAll(".short-info p");
            if (infos.length >= 2) 
                info_data.subtitle = infos[0].text;
            if (infos.length >= 1)
                info_data.summary = infos[infos.length - 1].text;

            let results = [];
            let nodes = doc.querySelectorAll('.chapter-box > li');
            for (let node of nodes) {
                let anode = node.querySelector('div.chapter-name.long a');
                let item = glib.DataItem.new();
                item.type = glib.DataItem.Type.Chapter;
                console.log("mark 4");
                let name = anode.text.trim();
                item.title = name.replace(/new$/, '');
                if (name.match(/new$/)) {
                    item.subtitle = 'new';
                }
                item.link = anode.attr('href');
                results.push(item);
            }
            
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(data) {
    return BookCollection.new(data);
};