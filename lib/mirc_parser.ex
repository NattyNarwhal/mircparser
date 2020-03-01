defmodule MircParser do
  @moduledoc """
  Parse mIRC colour codes and render to HTML.

  The characters used for each kind of formatting are:
  * "x02": Bold. Represented with `<b>`.
  * "x1D": Italic. Represented with `<i>`.
  * "x1F": Underline. Represented with `<u>`.
  * "x16": Reverse text. Represented with a span of class `reverse`.
  * "x0F": Strips all formatting.
  * "x03<ASCII int>": Sets the foreground colour. This is represented with a
    san of class `fg<int>`.
  * "x03<ASCII int>,<ASCII int>": Sets the foreground and background colour.
    This is represented with a span of classes `fg<int> bg<int>`.
  * "x03": Terminates colouring.

  The colour codes are:

  * 0: White (#FFFFFF)
  * 1: Black (#000000)
  * 2: Navy (#00007F)
  * 3: Green (#009300)
  * 4: Red (#FF0000)
  * 5: Maroon (#7F0000)
  * 6: Purple (#9C009C)
  * 7: Orange (#FC7F00)
  * 8: Yellow (#FFFF00)
  * 9: Light Green (#00FC00)
  * 10: Teal (#009393)
  * 11: Cyan (#00FFFF)
  * 12: Blue (#0000FC)
  * 13: Pink (#FF00FF)
  * 14: Grey (#7F7F7F)
  * 15: Light Grey (#D2D2D2)
  """

  require Integer
  
  @doc ~S"""
  Converts a string of mIRC formatted text into tokens.

  ## Examples

      iex> MircParser.parse("plain\x1Ditalic")
      ["plain", :italic, "italic"]

  """
  def parse(string) do
    string
    |> List.wrap
    |> Enum.map(&tokenize_colour_fg_bg/1)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x02", :bold) end)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x1D", :italic) end)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x1F", :underline) end)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x16", :reverse) end)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x0F", :plain) end)
    |> List.flatten
    |> Enum.map(fn str -> tokenize(str, "\x03", :color) end)
    |> List.flatten
  end
  
  defp tokenize_colour_match({val, idx}) do
    if Integer.is_even(idx) do
      val
    else
      tval = String.trim_leading(val, "\x03")
      case String.split(tval, ",") do
	[fg, bg] -> {:color, fg, bg}
	[fg] -> {:color, fg}
      end
    end
  end
  
  defp tokenize_colour_fg_bg(string) when is_binary(string) do
    matches = Regex.split(~r{\x03[0-9]+(?:,[0-9]+)?}, string, include_captures: true)
    matches # Because map_every doesn't take an offset
    |> Enum.with_index
    |> Enum.map(&tokenize_colour_match/1)
  end

  defp tokenize_colour_fg_bg(obj) do
    obj
  end
  
  defp tokenize(string, symbol, token) when is_binary(string) do
    string
    |> String.split(symbol)
    |> Enum.intersperse(token)
  end

  defp tokenize(obj, _, _) do
    obj
  end

  defp open_tag(token) do
    case token do
      :bold -> "<b>"
      :italic -> "<i>"
      :underline -> "<u>"
      :reverse -> "<span class=\"reverse\">"
      :color -> "<span class=\"color-invalid\">"
      {:color, foreground} ->
	"<span class=\"fg#{foreground}\">"
      {:color, foreground, background} ->
	"<span class=\"fg#{foreground} bg#{background}\">"
    end
  end

  defp close_tag(token) do
    case token do
      :bold -> "</b>"
      :italic -> "</i>"
      :underline -> "</u>"
      :reverse -> "</span>"
      :color -> "</span>"
      {:color, _} -> "</span>"
      {:color, _, _} -> "</span>"
    end
  end

  defp close_tag_stack(tag_stack) do
    tag_stack
    |> Enum.map(&close_tag/1)
    |> Enum.join
  end

  defp open_tag_stack(tag_stack) do
    tag_stack
    |> Enum.map(&open_tag/1)
    |> Enum.join
  end

  defp just_tag(tuple) when is_tuple(tuple) do
    elem(tuple, 0)
  end

  defp just_tag(tag) do
    tag
  end
  
  defp not_token(popped, token) do
    # If we find a :color on the left (regardless of what it is),
    # make sure just :color without a tuple will match it.
    just_tag(popped) != token
  end

  defp find_colour_token(popped) do
    just_tag(popped) != :color
  end
  
  defp handle_token(token, tag_stack) do
    case Enum.split_while(tag_stack, &not_token(&1, token)) do
      {_, []} -> # Not found
	# Special case: if any colour is on stack, and our token is a colour
        # tuple, pop until we hit it. (If we didn't care, we could just elide
	# this entire if part and just use the else. Alas, it's ugly.)
	if just_tag(token) == :color do
	  case Enum.split_while(tag_stack, &find_colour_token/1) do
	    {to_close, [head | tail]} ->
	      # Like the regular have-to-close case...
	      {[token] ++ to_close ++ tail,
	       close_tag_stack(to_close ++ [head])
	       <> open_tag_stack(to_close)
	       <> open_tag(token)}
	    _ -> {[token | tag_stack], open_tag(token)}
	  end
	else
	  {[token | tag_stack], open_tag(token)}
	end
      {to_close, [head | tail]} ->
	# Reopen anything caught if we had to close something in the middle.
	{to_close ++ tail,
	 close_tag_stack(to_close ++ [head]) <> open_tag_stack(to_close)}
    end
  end

  # mIRC reuses the background if it's set.
  defp backgroundize({:color, fg}, tag_stack) do
    Enum.find_value(tag_stack, {:color, fg}, fn tag ->
      case tag do
	{:color, _, bg} -> {:color, fg, bg}
	_ -> false
      end
    end)
  end
  
  defp render(input, tag_stack, output) do
    case input do
      [:plain | tail] ->
	render(tail, [], output <> close_tag_stack(tag_stack))
      [token | tail] when token in [:bold, :italic, :underline, :reverse, :color] ->
	{new_tag_stack, new_output} = handle_token(token, tag_stack)
	render(tail, new_tag_stack, output <> new_output)
      [{:color, fg, bg} | tail] ->
	{new_tag_stack, new_output} = handle_token({:color, fg, bg}, tag_stack)
	render(tail, new_tag_stack, output <> new_output)
      [{:color, fg} | tail] ->
	maybe_bg = backgroundize({:color, fg}, tag_stack)
	{new_tag_stack, new_output} = handle_token(maybe_bg, tag_stack)
	render(tail, new_tag_stack, output <> new_output)
      [head | tail] when is_binary(head) ->
	render(tail, tag_stack, output <> head)
      [] ->
	output <> close_tag_stack(tag_stack)
    end
  end

  @doc ~S"""
  Turns a string with mIRC formatting into an HTML string.

  ## Examples

      iex> MircParser.render("foo\x02bar")
      "foo<b>bar</b>"

  """
  def render(string) when is_binary(string) do
    render(parse(string))
  end

  @doc ~S"""
  Turns a list of tokens into an HTML string.

  ## Examples

      iex> MircParser.render(["foo", :bold, "bar"])
      "foo<b>bar</b>"

  """
  def render(tokens) when is_list(tokens) do
    render(tokens, [], "")
  end
end
