
class Settings < GS::Collection 

  def reload _, cb
    items = []
    items << GS::SettingItem.create(GS::SettingItem::Switch, 'desktop', 'Desktop Mode', false)
    setData items
  end

end

$exports = GS::Callback.block do 
  Settings.create
end