
function parseData(text) {
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

module.exports = async function(url) {
    let res = await fetch(url, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
        }
    });
    let text = await res.text();

    return parseData(text);
}