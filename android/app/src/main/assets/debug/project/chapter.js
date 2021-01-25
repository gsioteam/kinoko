const {Collection} = require('./collection');
const {LZString} = require('./lzstring');

class ChapterCollection extends Collection {

    async fetch(root_url) {
        let doc = await super.fetch(root_url);

        let res_script;
        let scripts = doc.querySelectorAll('script:not([src])');
        for (let script of scripts) {
            let text = script.text.trim();
            if (text.match(/^window\[/)) {
                res_script = text;
                break;
            }
        }

        if (res_script) {
            let ctx = glib.ScriptContext.new('v8');
            ctx.eval(LZString);
            ctx.eval("var window = global; var result; var SMH={imgData:function(data) {result=data;return {preInit: function(){return result;}}}}");
            console.log(res_script);
            let result = ctx.eval(res_script).toObject();
            let host_url = "https://i.hamreus.com";

            let results = [];
            for (let file of result.files) {
                let item = glib.DataItem.new();
                item.picture = `${host_url}${result.path}${file}?e=${result.sl.e}&m=${result.sl.m}`;
                item.link = root_url;
                item.data = {
                    headers: {
                        referer: "https://www.manhuagui.com/"
                    }
                };
                results.push(item);
            }
            return results;
        } else {
            return [];
        }
    }

    reload(_, cb) {
        this.fetch(this.url).then((results) => {
            this.setData(results);
            cb.apply(null);
        }).catch((err) => {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            console.error(err.msg);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function (data) {
    return ChapterCollection.new(data);
};