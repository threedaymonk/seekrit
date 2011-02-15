require 'tempfile'

module Seekrit
  class Interactor
    EDITOR = ENV['EDITOR'] || 'vi'
    RANDOM_SOURCE = '/dev/urandom'

    attr_reader :store

    def initialize(store)
      @store = store
    end

    def show(names)
      puts *names.map{ |n| [n, store[n] || "(None)", ""].compact }.flatten
    end

    def edit(names)
      names.each do |name|
        comment = "\# #{name}\n"
        data = comment + (store[name] || '')
        external_editor(data) do |data|
          data.sub!(/\A#{Regexp.escape(comment)}/, '')
          store[name] = data
          store.save
        end
      end
    end

    def delete(names)
      names.each do |name|
        store.delete(name)
      end
      store.save
    end

    def list(patterns)
      if patterns.empty?
        regexp = /.*/
      else
        regexp = /#{ patterns.map{ |p| Regexp.escape(p) }.join('|') }/
      end
      store.keys.sort_by{ |a| a.upcase }.each do |name|
        puts name if name =~ regexp
      end
    end

    def rename(old_name, new_name)
      store.rename(old_name, new_name)
      store.save
    end

    def export(filename)
      File.open(filename, 'w') do |io|
        store.export io
      end
    end

    def import(filename)
      File.open(filename, 'r') do |io|
        store.import io
        store.save
      end
    end

  private

    def shred(filename, cycles=1)
      data_length = File.stat(filename).size
      File.open(filename, 'wb') do |io|
        cycles.times do
          io.rewind
          io << random_bytes(data_length)
          io.flush
        end
      end
    end

    def random_bytes(num_bytes)
      File.open(RANDOM_SOURCE){ |io| io.read(num_bytes) }
    end

    def external_editor(data, &blk)
      tempfile = Tempfile.new('seekrit')
      tempfile << data
      tempfile.close
      mtime = File.stat(tempfile.path).mtime
      system( EDITOR + ' ' + tempfile.path )
      if File.stat(tempfile.path).mtime == mtime
        puts('No modifications.')
      else
        yield File.read(tempfile.path)
      end
      shred(tempfile.path)
    end

  end
end

