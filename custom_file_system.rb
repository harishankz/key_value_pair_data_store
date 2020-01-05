require 'singleton'

module CustomThreadSafe
  class CustomFileSystem
    include Singleton

    def initialize
      @mutex = Mutex.new
      @files = {}
    end

    def open(path)
      path = File.absolute_path(path)
      file = nil
      @mutex.synchronize do
        file = File.open(path, 'a')
      end
      yield file
    ensure
      @mutex.synchronize do
        file.close
      rescue => e
        raise (Errno::EACCES)
      end
    end
  end
end

