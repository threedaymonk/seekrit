require 'digest/sha2'
require 'openssl'
require 'yaml'

module Seekrit
  class DecryptionError < RuntimeError
  end
  
  class Store
    CIPHER = 'aes-256-cbc'
    
    attr_reader :secrets

    def initialize(password, path, cipher=CIPHER)
      @password, @path, @cipher = password, path, cipher
      @secrets = load_data
    end
    
    def retrieve(name)
      secrets[name]
    end

    def update(name, data)
      secrets[name] = data
    end

    def delete(name)
      secrets.delete(name)
    end

    def rename(oldname, newname)
      secrets[newname] = secrets[oldname]
      secrets.delete(oldname)
    end

    def list
      secrets.keys.sort
    end

    def save
      save_data(secrets)
    end

    def key
      Digest::SHA256.digest(@password)
    end

  private

    def load_data
      if File.exist?(@path)
        return YAML.load( decrypt( File.read( @path )))
      else
        return {}
      end
    end

    def save_data(data)
      File.open(@path, 'w') do |io|
        io << encrypt( YAML.dump( data ))
      end
    end

    def encrypt(data)
      cipher = OpenSSL::Cipher::Cipher.new(@cipher)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv = cipher.random_iv
      ciphertext = cipher.update(data)
      ciphertext << cipher.final
      return iv + ciphertext
    end

    def decrypt(data)
      cipher = OpenSSL::Cipher::Cipher.new(@cipher)
      iv = data[0, cipher.iv_len]
      ciphertext = data[cipher.iv_len..-1]
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      plaintext = cipher.update(ciphertext)
      plaintext << cipher.final
      return plaintext
    rescue OpenSSL::CipherError => err
      raise DecryptionError, err.message
    end
  end
end
