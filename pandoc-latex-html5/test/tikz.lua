local system = require 'pandoc.system'

local tikz_doc_template = [[
\documentclass{standalone}
\usepackage{xcolor}
\usepackage{tikz}
\begin{document}
\nopagecolor
%s
\end{document}
]]

local function file_exists(name)
  local f = io.open(name, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function starts_with(start, str)
  return str:sub(1, #start) == start
end

local function read_file(filepath)
  local f = io.open(filepath, 'rb')
  if not f then return nil end
  local content = f:read('*all')
  f:close()
  return content
end

local function url_encode(str)
  -- URL encode (percent encode) a string, similar to encodeURIComponent
  -- Keep safe characters unencoded: A-Z a-z 0-9 - _ . ! ~ * ' ( )
  local result = ''
  for i = 1, #str do
    local char = str:sub(i, i)
    local byte = string.byte(char)
    
    -- Check if character is safe (unreserved)
    if (byte >= 65 and byte <= 90) or   -- A-Z
       (byte >= 97 and byte <= 122) or  -- a-z
       (byte >= 48 and byte <= 57) or   -- 0-9
       char == '-' or char == '_' or char == '.' or 
       char == '!' or char == '~' or char == '*' or 
       char == "'" or char == '(' or char == ')' then
      result = result .. char
    else
      -- Encode as %XX
      result = result .. string.format('%%%02X', byte)
    end
  end
  
  return result
end

local function tikz2svg(src)
  local svg_content = nil
  
  system.with_temporary_directory('tikz2image', function (tmpdir)
    system.with_working_directory(tmpdir, function()
      local f = io.open('tikz.tex', 'w')
      f:write(tikz_doc_template:format(src))
      f:close()
      os.execute('latexmk -interaction=nonstopmode tikz.tex 2>&1 >/dev/null')
      os.execute('pdf2svg tikz.pdf tikz.svg 2>&1 >/dev/null')
      
      if file_exists('tikz.svg') then
        svg_content = read_file('tikz.svg')
      end
    end)
  end)
  
  return svg_content
end

function RawBlock(el)
  if starts_with('\\begin{tikzpicture}', el.text) then
    local svg_content = tikz2svg(el.text)
    
    if svg_content then
      -- Encode SVG as URL-encoded data URL (like encodeURIComponent)
      local encoded_svg = url_encode(svg_content)
      local data_url = 'data:image/svg+xml,' .. encoded_svg
      
      return pandoc.Para({pandoc.Image({}, data_url)})
    else
      io.stderr:write('Warning: Failed to convert TikZ to SVG\n')
      return el
    end
  else
   return el
  end
end
