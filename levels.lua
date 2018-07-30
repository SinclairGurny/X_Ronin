-- Level reading and loading

local L ={}

function L.splitNumbers( str )
   local results = {};
   for m in str:gmatch("[^%s]+") do
      results[#results+1] = m+0;
   end
   return results
end

function L.splitLine( str, width )

end

function L.readLevels()

   local allLevels = {}
   
   contents, size = love.filesystem.read('assets/levels.txt')
   -- Setup
   local str = contents
   local start = 1
   local i, tmp = string.find( str, '\n' )

   local mode = 0
   local tmp_x, tmp_y = 0,0
   local count = 0
   
   while i ~= nil do
      local sub = string.sub( str, 1, i )
      local rest = string.sub( str, i+1 )

      if mode == 0 then -- level number
	 print(tonumber(sub))
	 mode = mode + 1
      elseif mode == 1 then -- size_x, size_y
	 local size = L.splitNumbers( sub )
	 print( size[1], size[2] )
	 mode = mode + 1
      elseif mode == 2 then -- board line
	 print(sub)
      end
      

      str = rest
      i, tmp = string.find(str, '\n')
   end

   
end

--export namespace
return L
