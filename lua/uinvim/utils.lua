function Dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. Dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Switch(value)
  return function(cases)
    local case = cases[value] or cases.default
    if case then
      return case
    else
      error(string.format("Unhandled case (%s)", value, 2))
    end
  end
end
