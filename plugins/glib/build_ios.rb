#!/usr/bin/ruby

require 'fileutils'

$dirs = {}


def mkdir path
    FileUtils.mkdir path unless File.exist? path
end

def ex_lib path, exclude = []
    res = `lipo -info #{path}`
    dir = File.dirname path
    archs = res[/[^:$]+$/].strip
    
    if res[/non-fat/i]
        tar_dir = "#{dir}/#{archs}"
        tar_name = path[/[^\/]+$/]
        mkdir tar_dir
        old_dir = Dir.pwd
        FileUtils.cp path, "#{tar_dir}/#{tar_name}"
        obj_dir = "#{tar_dir}/#{tar_name.gsub(/\.a$/, '')}"
        arr = $dirs[tar_dir]
        unless arr 
            arr = $dirs[tar_dir] = []
        end
        arr << obj_dir
        mkdir obj_dir
        Dir.chdir obj_dir
        `ar -x "#{tar_dir}/#{tar_name}"`
        Dir.chdir old_dir
    else
        archs.split(' ').each do |arch|
            next if (exclude.count(arch) > 0) 
            tar_dir = "#{dir}/#{arch}"
            tar_name = path[/[^\/]+$/]
            mkdir tar_dir
            old_dir = Dir.pwd
            `lipo "#{path}" -thin #{arch} -output "#{tar_dir}/#{tar_name}"`
            obj_dir = "#{tar_dir}/#{tar_name.gsub(/\.a$/, '')}"
            arr = $dirs[tar_dir]
            unless arr 
                arr = $dirs[tar_dir] = []
            end
            arr << obj_dir
            mkdir obj_dir
            Dir.chdir obj_dir
            `ar -x "#{tar_dir}/#{tar_name}"`
            Dir.chdir old_dir

        end
    end
end

def main 
    dir = File.expand_path(File.dirname(__FILE__))
    
    configuration = if ARGV[0] == 'debug' then 'Debug' else 'Release' end

    `cmake -G Xcode -B "#{dir}/build/ios" -DCMAKE_SYSTEM_NAME=iOS "#{dir}"`
    
    `xcodebuild IPHONEOS_DEPLOYMENT_TARGET=8.0 -project "#{dir}/build/ios/glib.xcodeproj" -scheme glib -sdk iphoneos -configuration #{configuration} -UseModernBuildSystem=NO clean build CONFIGURATION_BUILD_DIR="#{dir}/build/lib/iphoneos"`
    
    `xcodebuild IPHONEOS_DEPLOYMENT_TARGET=8.0 -project "#{dir}/build/ios/glib.xcodeproj" -scheme glib -sdk iphonesimulator -configuration #{configuration} -UseModernBuildSystem=NO clean build CONFIGURATION_BUILD_DIR="#{dir}/build/lib/iphonesimulator"`
    
    iphoneos_dir = "#{dir}/build/lib/iphoneos" 
    iphonesimulator_dir = "#{dir}/build/lib/iphonesimulator" 

    Dir["#{iphoneos_dir}/*.a"].each do |file|
        ex_lib file
    end

    Dir["#{iphonesimulator_dir}/*.a"].each do |file|
        ex_lib file, ['arm64']
    end

    $dirs.each do |dir, arr|
        `ar -rcs "#{dir}/ligglib_ios.a" #{arr.map{|f| "#{f}/*o"}.join(' ')}`
    end

    mkdir "#{dir}/ios/lib"
    mkdir "#{dir}/ios/include"
    `lipo -create #{$dirs.keys.map{|d| "#{d}/ligglib_ios.a"}.join(' ')} -output #{dir}/ios/lib/libglib_ios.a`

    # FileUtils.cp "#{dir}/thirdparties/mruby/lib/ios/libmruby.a", "#{dir}/ios/lib/libmruby.a"
    Dir["#{dir}/thirdparties/openssl/ios/lib/*.a"].each do |file|
        FileUtils.cp file, "#{dir}/ios/lib/#{file[/[^\/]+$/]}"
    end
    FileUtils.cp "#{dir}/src/application/dart_main_ios.h", "#{dir}/ios/include/dart_main_ios.h"
end

main