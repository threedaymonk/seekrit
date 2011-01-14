lib = File.expand_path('../../lib', __FILE__)
$:.unshift lib unless $:.include?(lib)
require "test/unit"
require "seekrit/store"

class StoreTest < Test::Unit::TestCase
  include Seekrit

  def test_should_initialize_empty_store
    store = Store.new("anything", StringIO.new)
    assert_equal [], store.keys
  end

  def test_should_save_and_retrieve_with_arbitrary_key
    buffer = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer))
    s1["foo\tbar"] = "baz"
    s1.save

    s2 = Store.new("rhubarb", StringIO.new(buffer))
    assert_equal "baz", s2["foo\tbar"]
  end

  def test_should_not_decrypt_with_wrong_password
    buffer = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    assert_raises DecryptionError do
      s2 = Store.new("custard", StringIO.new(buffer))
    end
  end

  def test_should_export_to_plain_text
    s1 = Store.new("rhubarb", StringIO.new)
    s1["foo"] = "new\nline"
    s1["bar"] = "backslash\\and\ttab"
    exported = ""
    s1.export(StringIO.new(exported))
    assert_equal "bar\tbackslash\\\\and\\ttab\nfoo\tnew\\nline\n", exported
  end

  def test_should_import_from_plain_text
    s1 = Store.new("anything1", StringIO.new)
    s1["foo"] = "new\nline"
    s1["bar"] = "backslash\\and\ttab"
    exported = ""
    s1.export(StringIO.new(exported))

    s2 = Store.new("anything2", StringIO.new)
    s2.import(StringIO.new(exported))
    assert_equal "new\nline", s2["foo"]
    assert_equal "backslash\\and\ttab", s2["bar"]
  end

end
