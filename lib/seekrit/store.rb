require 'digest/sha2'
require 'openssl'
require 'yaml'

module Seekrit
  class DecryptionError < RuntimeError
  end
  
  class Store
    CIPHER = 'aes-256-cbc'
    
    attr_reader :secrets

    def initialize(password, file, cipher=CIPHER)
      @password = password
      @cipher   = cipher
      @file     = file
      @secrets  = load_data(file)
    end

    def keys
      secrets.keys
    end

    def [](name)
      secrets[name] && decrypt(secrets[name])
    end

    def []=(name, value)
      secrets[name] = encrypt(value)
    end
    
    def delete(name)
      secrets.delete(name)
    end

    def rename(oldname, newname)
      self[newname] = self[oldname]
      delete(oldname)
    end

    def save
      @file.rewind
      secrets.sort_by{ |k,_| k }.each do |name, value|
        @file << escape(name) << "\t" << hexdump(value) << "\n"
      end
    end

    def export(io)
      secrets.sort_by{ |k,_| k }.each do |name, value|
        io << escape(name) << "\t" << escape(decrypt(value)) << "\n"
      end
    end

    def import(io)
      secrets.clear
      while line = io.gets
        name, data = line.chomp.split(/\t/, 2).map{ |a| unescape(a) }
        self[name] = data
      end
    end

  private

    def crypt_key
      Digest::SHA256.digest(@password.respond_to?(:call) ? @password.call : @password)
    end

    def escape(value)
      value.
        gsub(/\\/, "\\\\\\\\").
        gsub(/\t/, "\\\\t").
        gsub(/\n/, "\\\\n")
    end

    def unescape(value)
      value.
        gsub(/\\n/, "\n").
        gsub(/\\t/, "\t").
        gsub(/\\\\/, "\\\\")
    end

    def load_data(file)
      data = {}
      while line = file.gets
        a, b = line.split(/\t/, 2)
        data[unescape(a)] = hexload(b)
      end
      data
    end

    def hexdump(binary)
      binary.unpack('C*').map{ |a| "%02x" % a }.join
    end

    def hexload(hex)
      hex.scan(/../).map{ |a| a.to_i(16) }.pack('C*')
    end

    def encrypt(data)
      cipher = OpenSSL::Cipher::Cipher.new(@cipher)
      cipher.encrypt
      cipher.key = crypt_key
      cipher.iv = iv = cipher.random_iv
      ciphertext = cipher.update(data)
      ciphertext << cipher.final
      return iv + ciphertext
    end

    def decrypt(data)
      err = nil
      3.times do
        begin
          k = @correct_key || crypt_key
          decrypted = decrypt_once(data, k)
          @correct_key ||= k
          return decrypted
        rescue DecryptionError => err
        end
      end
      raise err
    end

    def decrypt_once(data, key)
      cipher = OpenSSL::Cipher::Cipher.new(@cipher)
      iv = data[0, cipher.iv_len]
      ciphertext = data[cipher.iv_len..-1]
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      plaintext = cipher.update(ciphertext)
      plaintext << cipher.final
      return plaintext
    rescue => err
      raise DecryptionError, err.message
    end
  end
end
