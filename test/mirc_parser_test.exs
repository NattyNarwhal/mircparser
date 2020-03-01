defmodule MircParserTest do
  use ExUnit.Case
  doctest MircParser

  test "it handles closing tags in the middle of a tag stack" do
    output = MircParser.render("\x01Foo\x1Dbar\x01Foo")
    assert output == "<b>Foo<i>bar</i></b><i>Foo</i>"
  end

  test "it handles automatically closing tags" do
    output1 = MircParser.render("\x01foo")
    assert output1 == "<b>foo</b>"
    output2 = MircParser.render("\x01foo\x1Dfoo")
    assert output2 == "<b>foo<i>foo</i></b>"
  end

  test "it clears all formatting" do
    output = MircParser.render("\x033Green\x01Bold\x0FPlain")
    assert output == "<span class=\"fg3\">Green<b>Bold</b></span>Plain"
  end

  test "it closes colour tags" do
    output = MircParser.render("\x033Green\x03Not Green")
    assert output == "<span class=\"fg3\">Green</span>Not Green"
  end

  test "it closes tags" do
    output1 = MircParser.render("\x01foo\x01")
    assert output1 == "<b>foo</b>"
    output1 = MircParser.render("\x01\x1Dfoo\x1D\x01")
    assert output1 == "<b><i>foo</i></b>"
  end

  test "it opens a new colour tag" do
    output1 = MircParser.render("\x033green text\x038yellow text")
    assert output1 == "<span class=\"fg3\">green text</span><span class=\"fg8\">yellow text</span>"
    output2 = MircParser.render("\x033green text\x038,3yellow text, green text")
    assert output2 == "<span class=\"fg3\">green text</span><span class=\"fg8 bg3\">yellow text, green text</span>"
  end

  test "it reuses the background colour" do
    output = MircParser.render("\x030,3green text, green background\x038yellow text, green background")
    assert output == "<span class=\"fg0 bg3\">green text, green background</span><span class=\"fg8 bg3\">yellow text, green background</span>"
  end
  
end
