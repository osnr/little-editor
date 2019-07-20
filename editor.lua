print("Running editor.lua!")

setdefaultfont("Menlo", 15)

function hook(s)
   removeattribute("NSColor", makerange(1, #s))

   local i, j = 0, 0
   while true do
      i, j = s:find('hi!', i + 1)
      if i == nil then break end
      addattribute("NSColor", makecolor("orangeColor"),
                   makerange(i, j - i + 1))
   end
end
