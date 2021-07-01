
class SettingsController extends glib.Collection {
    reload(data, cb) {
        let val = this.getSetting('sort_type');
        if (val == null || val == '') {
            val = 'recent';
        }
        this.setData([
            glib.SettingItem.new(
                glib.SettingItem.Type.Header,
                "general",
                "General"
            ),
            glib.SettingItem.new(
                glib.SettingItem.Type.Options,
                "sort_type",
                "Sort Type For Searching",
                val,
                [{
                    name: 'Recent',
                    value: 'recent'
                }, {
                    name: 'Popular Today',
                    value: 'popular-today'
                }, {
                    name: 'Popular Week',
                    value: 'popular-week'
                }, {
                    name: 'Popular All Time',
                    value: 'popular'
                }]
            ),
        ]);
    }
}

module.exports = function() {
    return SettingsController.new();
}