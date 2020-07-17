#!/usr/bin/ruby

require 'fileutils'

$path = if ARGV.size > 0 then ARGV[0] else Dir.pwd end

 
files = []

headers = nil
if File.file?($path)
  headers = [$path]
  $path = $path.gsub /\/[^\/]+$/, ''
else
  headers = Dir["#{$path}/**/*.h"]
end

class HMethod
  attr_accessor :name,
                :params,
                :labels,
                :all_labels

  def initialize name
    @name = name
  end
end

class HProperty
  attr_accessor :name,
                :getter,
                :setter,
                :labels,
                :all_labels

  def initialize name
    @name = name
  end
end

class HClass
  attr_accessor :name,
                :namespace,
                :real_namespace,
                :template,
                :header,
                :labels,
                :all_labels,
                :active,

                :methods,
                :properties,

                :has_onload,
                :onload_pre_offset,
                :onload_begin,
                :onload_end,
                :onload_new_line,
                :onload_super

  def initialize name
    @name = name
    @active = true
    @methods = {}
    @properties = {}
    @has_onload = false
    @onload_new_line = false
  end
end

$tmp_classes = {}
$include_classes = {}
$classes_index = {}
$untouched_classes = {}
$current_header = ''
$current_namespace = nil
$current_class = nil
$class_stack = []
$labels_stack = {}
$current_labels = nil

def p_labels labels
  str = 'map<string, Variant>{'
  labels.each do |key, value|
    str << "{#{key}, #{value}},"
  end
  str << '}'
end

def push_class cls
  fullname = "#{cls.namespace}::#{cls.name}"
  unless $include_classes.has_key?(fullname)
    cls.header = $current_header
    $include_classes[fullname] = cls
    $classes_index[cls.name] = fullname
  end
end

def check_namespace(args)
  if args[:line][/^[\s\t]*namespace[\s\t]*(\w+)/]
    yield $1
  end
end

def check_class_begin(args)
  if args[:line][/CLASS_BEGIN(\w*)\(([^\)]+)/]
    type = $1
    res = []
    res_cls = nil
    $2.gsub /[\w:]+/ do |w|
      res << w
    end
    if res.size > 0 and res[0] != 'NAME'
      is_tem = false
      if args[:index] > 0
        l = args[:lines][args[:index] - 1]
        is_tem = true if l[/^[\s\t]*template/]
      end
      cls_ns = nil
      cls_ns = $current_namespace if type[/N/]
      real_ns = $current_namespace
      if is_tem
        tp_cls = $tmp_classes[res[0]]
        unless tp_cls
          tp_cls = HClass.new res[0]
          tp_cls.namespace = cls_ns
          str = ''
          $class_stack.each{|clz| str << "::#{clz.name}"}
          tp_cls.real_namespace = "#{real_ns}#{str}"
          $tmp_classes[res[0]] = tp_cls
        end
        if $untouched_classes.has_key?(res[0])
          tp_cls.template = $untouched_classes[res[0]]
          $untouched_classes.delete res[0]
          push_class tp_cls
        end
        res_cls = tp_cls
      else
        cls = HClass.new res[0]
        cls.namespace = cls_ns
        str = ''
        $class_stack.each{|clz| str << "::#{clz.name}"}
        cls.real_namespace = "#{real_ns}#{str}"
        push_class cls
        res_cls = cls
      end
      if type[/T/]
        tmp = res[3..-1]
        if $tmp_classes.has_key? res[1]
          cls = $tmp_classes[res[1]]
          cls.template = tmp
          #push_class cls
        else
          $untouched_classes[res[1]] = tmp
        end
        res_cls.onload_super = "#{res[1]}<#{tmp}>"
      elsif type[/0/]
        res_cls.onload_super = 'gc::Base'
      else
        res_cls.onload_super = res[1]
      end

      yield res[0], res_cls
    end
  end
end

def check_class_end args
  return unless $current_class
  if args[:line][/CLASS_END/]
    yield args[:line].index /CLASS_END/
  end
end

def check_label args
  if args[:line][/LABEL\(([^\)]+)/]
    arr = $1.split ','
    if arr.size == 2
      yield arr
    end
  end
end

def check_labels args
  line = args[:line].strip
  if line[/LABELS\(([^$]+)/]
    str = $1[0...-1]
    yield str
  end
end

def check_method args
  return unless $current_class
  if args[:line][/ METHOD /] and str = args[:line][/(\w+)\(([^\)]*)/]
    yield $1, $2
  end
end

def check_property args
  return unless $current_class
  if args[:line][/[\t ^]PROPERTY\(([^\)]+)/]
    arr = $1.split ','
    yield arr[0].strip, arr[1].strip, arr[2].strip
  end
end

def check_on_load_begin args
  return unless $current_class
  if args[:line][/ON_LOADED_BEGIN\(([^\)]+)/]
    arr = $1.split ','
    yield args[:line].index(/ON_LOADED_BEGIN\(([^\)]+)/), arr
  end
end

def check_on_load_end args
  return unless $current_class
  if args[:line][/ON_LOADED_END/]
    yield args[:line].index(/ON_LOADED_END/) + 'ON_LOADED_END'.size
  end
end

CLASS_LABELS_TEMPLATE = 'cls->setLabels({{labels}})'

ADD_METHOD_TEMPLATE = %q[ADD_METHOD(cls, {{class}}, {{method}}{{labels}})]

ADD_PROPERTY_TEMPLATE = %q[ADD_PROPERTY(cls, "{{name}}", {{getter}}, {{setter}}{{labels}})]

ON_LOAD_BEGIN = 'ON_LOADED_BEGIN(cls, {{super}})'
ON_LOAD_END = 'ON_LOADED_END'

def check c, a, b
  if c
    a
  else
    b
  end
end

def process_labels str, object, dot = true
  if object.all_labels
    str.gsub! '{{labels}}', "#{check dot, ', ', ''}#{object.all_labels}"
  elsif object.labels.size > 0
    str.gsub! '{{labels}}', "#{check dot, ', ', ''}#{p_labels object.labels}"
  else
    str.gsub! '{{labels}}', ''
  end
end

def process_header header, content, classes
  changed = false

  classes.sort{|a,b| classes.index(b) <=> classes.index(a)}.each do |cls|
    if cls.methods.size > 0
      changed = true
      added_methods = []
      properties_strs = []
      cls.properties.each do |key, value|
        getter = cls.methods[value.getter]
        setter = cls.methods[value.setter]
        getter_str = ''
        setter_str = ''
        if getter
          getter_str = ADD_METHOD_TEMPLATE
                           .gsub('{{class}}', cls.name)
                           .gsub('{{method}}', getter.name)
          process_labels getter_str, getter
        else
          getter_str = 'NULL'
          #raise "Method not found: #{value.getter}"
        end
        if setter
          setter_str = ADD_METHOD_TEMPLATE
                           .gsub('{{class}}', cls.name)
                           .gsub('{{method}}', setter.name)
          process_labels setter_str, setter
        else
          setter_str = 'NULL'
          #raise "Method not found: #{value.setter}" unless setter
        end
        added_methods << getter.name if getter
        added_methods << setter.name if setter

        pro_str = ADD_PROPERTY_TEMPLATE
                      .gsub('{{name}}', value.name)
                      .gsub('{{getter}}', getter_str)
                      .gsub('{{setter}}', setter_str)
        process_labels pro_str, value
        properties_strs << pro_str

      end

      method_strs = []
      cls.methods.each do |key, value|
        unless added_methods.index key
          method = value
          method_str = ADD_METHOD_TEMPLATE
                           .gsub('{{class}}', cls.name)
                           .gsub('{{method}}', method.name)

          process_labels method_str, method

          method_strs << method_str
        end
      end

      space = ' ' * cls.onload_pre_offset
      str = ''
      unless cls.has_onload
        space << ' ' * 4
        str << "protected:\n#{space}"
      end
      str << ON_LOAD_BEGIN.gsub('{{super}}', cls.onload_super)
      str << "\n"

      if cls.labels.size > 0 or cls.all_labels
        str << space
        str << ' ' * 4
        lbs = CLASS_LABELS_TEMPLATE.clone
        process_labels(lbs, cls, false)
        str << lbs
        str << ";\n"
      end

      properties_strs.each do |s|
        str << space
        str << ' ' * 4
        str << s
        str << ";\n"
      end
      method_strs.each do |s|
        str << space
        str << ' ' * 4
        str << s
        str << ";\n"
      end
      str << space
      str << ON_LOAD_END
      str << "\n" if cls.onload_new_line
      unless cls.has_onload
        str << ' ' * cls.onload_pre_offset
        str << content[cls.onload_end]
      end
      content[cls.onload_begin..cls.onload_end] = str
    end
  end

  if changed
    target_path = header.gsub "#{$path}/", "#{$path}/tmp/"
    tmp_path = target_path.gsub /[^$\/]+$/, ''
    FileUtils.mkpath tmp_path
    p $path
    p "Move: #{header} to #{target_path}"
    FileUtils.move header, target_path, force: true

    p "Write new: #{header}"
    File.open header, 'w' do |f|
      f.write content
    end
  end
end

headers.each do |header|
  $current_header = header.gsub "#{$path}/", ''
  content = ''
  current_classes = []

  next if header["#{$path}/tmp/"]
  p "Start process #{header}:"
  File.open header, 'r' do |f|
    $current_namespace = nil
    $current_class = nil
    $labels_stack = {}
    $current_labels = nil
    $class_stack = []

    content = f.read
    length = content.size
    index = 0
    lines = []
    line = ''
    line_start = 0
    length.times do |offset|
      ch = content[offset]
      if ch == "\n"

        lines << line

        params = {line: line, lines: lines, index: index}
        check_namespace params do |res|
          p "--> Enter namespace: #{res}"
          $current_namespace = res
        end

        check_class_begin params do |res, cls|
          p "--> Class begin: #{res}"
          $class_stack << cls
          $current_class = cls

          if cls.active
            cls.all_labels = $current_labels
            cls.labels = $labels_stack
          end
          $labels_stack = {}
          $current_labels = nil
        end

        check_class_end params do |off|
          p "--> Class end: #{off}"
          if $current_class
            $class_stack.pop if $class_stack.size >= 1
            if $current_class.active
              current_classes << $current_class
            end
            $current_class.active = false
            unless $current_class.has_onload
              $current_class.onload_begin = $current_class.onload_end = line_start + off
              $current_class.onload_pre_offset = off
              $current_class.onload_new_line = true
            end
            if $class_stack.size > 0
              $current_class = $class_stack.last
            end
          end
        end

        check_label params do |res|
          p "--> A label: #{res[0].strip} => #{res[1].strip}"
          $labels_stack[res[0].strip] = res[1].strip
        end

        check_labels params do |res|
          p "--> Labels: #{res}"
          $current_labels = res
        end

        check_method params do |name, ps|
          p "--> A method: #{name}"
          if $current_class && $current_class.active
            method = HMethod.new name
            method.params = ps

            method.all_labels = $current_labels
            method.labels = $labels_stack
            $labels_stack = {}
            $current_labels = nil
            if $current_class.active
              $current_class.methods[name] = method

            end
          end
        end

        check_property params do |name, getter, setter|
          p "--> A property: #{name}"
          property = HProperty.new name
          property.setter = setter
          property.getter = getter

          property.all_labels = $current_labels
          property.labels = $labels_stack
          $labels_stack = {}
          $current_labels = nil
          if $current_class.active
            $current_class.properties[name] = property
          end
        end

        check_on_load_begin params do |off, ps|
          p "--> On load method: #{off}"
          if $current_class.active
            $current_class.onload_begin = line_start + off
            $current_class.onload_pre_offset = off
          end
        end

        check_on_load_end params do |off|
          if $current_class.active
            $current_class.onload_end = line_start + off - 1
          end
          $current_class.has_onload = true
        end

        line_start = offset + 1
        index += 1
        line = ''
      else

        line << ch

      end

    end

  end

  process_header header, content, current_classes
end

LOAD_CLASSES_TEMPLATE = %q[
{{header}}

using namespace gc;

void ClassDB::loadClasses() {
    //class_loaders[h("gc::Base")] = (void*)&gc::Base::getClass;
{{loaders}}
}
]

def process_load_classes
  headers = []
  loaders = []

  $include_classes.each do |key, cls|
    headers << "#include \"#{cls.header}\""
    loader = "    "
    loader << "class_loaders[h(\"#{if cls.namespace then "#{cls.namespace}::" else '' end}#{cls.name}\")]"
    loader << " = (void*)&#{if cls.real_namespace then "#{cls.real_namespace}::" else '' end}#{cls.name}"
    if cls.template and cls.template.size > 0
      loader << '<'
      narr = cls.template.map do |t|
        if $classes_index[t]
          $classes_index[t]
        else
          t
        end
      end
      loader << narr * ','
      loader << '>'
    end
    loader << '::getClass;'
    loaders << loader

  end

  target_path = "#{$path}/Classes.cpp"
  File.delete target_path if File.exist? target_path
  File.open target_path, 'w' do |f|
    content = LOAD_CLASSES_TEMPLATE.gsub '{{header}}', headers.uniq * "\n"
    content = content.gsub '{{loaders}}', loaders * "\n"
    f.write content
  end
end

if headers.size > 1
  process_load_classes
end
