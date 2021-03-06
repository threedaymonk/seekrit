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

  def test_should_save_and_retrieve_with_lambda_as_key
    password = lambda{ "rhubarb" }
    buffer = ""
    s1 = Store.new(password, StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    s2 = Store.new(password, StringIO.new(buffer))
    assert_equal "bar", s2["foo"]
  end

  def test_should_call_password_up_to_three_times_on_error
    called = 0
    password = lambda{
      called += 1
      if called == 3
        "correct"
      else
        "incorrect"
      end
    }

    buffer = ""
    s1 = Store.new("correct", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    s2 = Store.new(password, StringIO.new(buffer))
    assert_equal "bar", s2["foo"]
    assert_equal "bar", s2["foo"]

    assert_equal 3, called
  end

  def test_should_remember_correct_password
    called = 0
    password = lambda{
      called += 1
      "correct"
    }

    buffer = ""
    s1 = Store.new("correct", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    s2 = Store.new(password, StringIO.new(buffer))
    s2["foo"]
    assert_equal 1, called

    s2["foo"] = "baz"
    s2.save
    assert_equal 1, called
  end

  def test_should_enforce_existing_password
    buffer = ""
    s1 = Store.new("correct", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    assert_raises PasswordError do
      s2 = Store.new("incorrect", StringIO.new(buffer))
      s2["baz"] = "quux"
      s2.save
    end
  end

  def test_should_return_nil_for_non_existent_entry
    buffer = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer))
    assert_nil s1["foo"]
  end

  def test_should_not_change_unchanged_entries_when_saving
    buffer1 = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer1))
    s1["foo"] = "bar"
    s1.save

    buffer2 = buffer1.dup
    s2 = Store.new("rhubarb", StringIO.new(buffer2))
    s2.save

    assert_equal buffer1, buffer2
  end

  def test_should_not_decrypt_with_wrong_password
    buffer = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    assert_raises PasswordError do
      s2 = Store.new("custard", StringIO.new(buffer))
      s2["foo"]
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

  def test_should_not_need_password_for_list
    buffer = ""
    s1 = Store.new("rhubarb", StringIO.new(buffer))
    s1["foo"] = "bar"
    s1.save

    s2 = Store.new(lambda{ raise "called" }, StringIO.new(buffer))
    assert_equal ["foo"], s2.keys
  end

end
