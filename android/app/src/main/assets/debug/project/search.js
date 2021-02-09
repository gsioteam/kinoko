
const {ParsedCollection} = require('./collection');

class SearchCollection extends ParsedCollection {
    
    constructor(data) {
        super(data);
    }

    makeURL() {
        let lang = this.getSetting('language');
        return this.url.replace('{0}', lang).replace('{1}', glib.Encoder.urlEncode(this.key));
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        if (!this.key) return false;
        this.fetch(this.makeURL()).then((results)=>{
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
    return SearchCollection.new(data ? data.toObject() : {});
};