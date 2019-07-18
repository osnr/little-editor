print("Running language.lua!")

setdefaultfont("Menlo", 15)

function hook(s)
   print(math.floor(#s /2))
   removeattribute("NSBackgroundColor", makerange(1, #s))
   addattribute("NSBackgroundColor", makecolor("orangeColor"), makerange(1, math.floor(#s/2)))
   print("new string: ["..s.."]")
end
