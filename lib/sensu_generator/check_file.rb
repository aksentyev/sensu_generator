require 'fileutils'

module SensuGenerator
  class CheckFile
    def self.remove_all_with(prefix)
      FileUtils.rm(Dir.glob("#{Application.config.result_dir}/#{prefix}*"))
    end

    def initialize(filename)
      @config   = Application.config
      @trigger  = Application.trigger
      @filename = filename
      @fullpath = File.join(@config.result_dir, @filename)
    end

    def write(data)
      file = File.open(@fullpath, 'w+')
      file.write data
      file.close
      @trigger.touch
    end

    def remove
      FileUtils.rm @fullpath
    end
  end
end
