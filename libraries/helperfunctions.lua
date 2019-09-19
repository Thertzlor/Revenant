local tl = ...
local gmatch, setmetatable, type,pairs = 
string.gmatch, setmetatable, type,pairs
--Library Functions from around the net... =======================================================================================
function tl.Reverse(arr)
  local i, j = 1, #arr
  while i < j do
    arr[i], arr[j] = arr[j], arr[i]
    i = i + 1
    j = j - 1
  end
end

function tl.dump(o)
  if type(o) == 'table' then
    local s = ''
    for k in pairs(o) do
      if type(k) ~= 'number' then k = k end
      s = s..k.."  "
    end
    return s .. ''
  else
    return tostring(o)
  end
end

function tl.wipe(tab)
  for k in pairs(tab) do
    tab[k] = nil
  end
end

function tl.splitter(str,sep)
  local ret={}
  local n=1
  for w in gmatch(str,"([^"..sep.."]*)") do
     ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
     if w=="" then
        n = n + 1
     end -- step forwards on a blank but not a string
  end
  return ret
end

function tl.deepcopy(orig, copies, parent)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[tl.deepcopy(orig_key, copies,parent)] = tl.deepcopy(orig_value, copies,parent)
          end
          copies[orig] = copy
          setmetatable(copy, tl.deepcopy(getmetatable(orig), copies,parent))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  if type(copy) == "table" then tl.tablecrawl(copy,nil,nil,parent) end
  return copy
end

local print_orig, type, floor,      min,      max,      sqrt,      format,        byte,        char,        rep,        sub,        gsub,        concat,       select, tostring =
   print,      type, math.floor, math.min, math.max, math.sqrt, string.format, string.byte, string.char, string.rep, string.sub, string.gsub, table.concat, select, tostring


do
   local xy_data, xy_64K, xy_pixels, enabled = {{}, {}}, {}, {}, true

   function GetMousePositionInPixels()
      -- The function returns mouse_x_pixels, mouse_y_pixels, screen_width, screen_height, x_64K, y_64K
      -- 0 <= mouse_x_pixels < screen_width
      -- 0 <= mouse_y_pixels < screen_height
      -- both width and height of your screen must be between 150 and 10240 pixels
      xy_64K[1], xy_64K[2] = GetMousePosition()
      if enabled then
         local jump
         local attempts_qty = 3   -- number of failed attempts to determine screen resolution prior to disabling this functionality
         for attempt = 1, attempts_qty + 1 do
            for i = 1, 2 do
               local result
               local size = xy_data[i][4]
               if size then
                  local coord_64K = xy_64K[i]
                  -- How to convert between pos_64K_x (0...65535) and pixel_x (0...(screen_width-1))
                  --    pos_64K_x = floor(pixel_x * (2^16-1) / (screen_width-1) + 0.5)
                  --    pixel_x   = floor((pos_64K_x + (0.5 + 2^-16)) * (screen_width-1) / (2^16-1))
                  local pixels = floor((coord_64K + (0.5 + 2^-16)) * (size - 1) / 65535)
                  if 65535 * pixels >= (coord_64K - (0.5 + 2^-16)) * (size - 1) then
                     result = pixels
                  end
               end
               xy_pixels[i] = result
            end
            if xy_pixels[1] and xy_pixels[2] then
               return xy_pixels[1], xy_pixels[2], xy_data[1][4], xy_data[2][4], xy_64K[1], xy_64K[2]
            elseif attempt <= attempts_qty then
               --print("Attempt #"..attempt)
               if jump then
                  MoveMouseTo(3*2^14 - xy_64K[1]/2, 3*2^14 - xy_64K[2]/2)
                  tl.wait(10)
                  xy_64K[1], xy_64K[2] = GetMousePosition()
               end
               jump = true
               for _, data in ipairs(xy_data) do
                  data[1] = {[0] = true}                 -- [1] = dict with used coord_64K values
                  data[2] = 0                            -- [2] = used coord_64K values qty
                  data[3] = 45 * 225                     -- [3] = counter of possible sizes
                  data[4] = nil                          -- [4] = minimal possible size
                  data[5] = 6                            -- [5] = only pointer to next number (in 8 lowest bits)
                  for j = 6, 229 do                      -- [6]..[230] = 53-bit numbers
                     data[j] = (2^45 - 1) * 256 + 1 + j  --    8 lowest bits   = index of the next number (last number points to idx=0)
                  end                                    --    45 highest bits = flags (1 = size is possible, 0 = size is impossible)
                  data[230] = (2^45 - 1) * 256
               end
               local dx = xy_64K[1] < 2^15 and 1 or -1
               local dy = xy_64K[2] < 2^15 and 1 or -1
               local prev_coords_processed_1, prev_coords_processed_2, prev_variants_qty, trust
               for frame = 1, 90 * attempt do
                  for i = 1, 2 do
                     local data, coord_64K = xy_data[i], xy_64K[i]
                     local data_1 = data[1]
                     if not data_1[coord_64K] then
                        data_1[coord_64K] = true
                        data[2] = data[2] + 1
                        local min_size
                        local prev_idx = 5
                        local idx = data[prev_idx]
                        while idx > 0 do
                           local N = data[idx]
                           local mask = 2^53
                           local size_from = idx * 45 + (150 - 6 * 45)
                           for size = size_from, size_from + 44 do
                              mask = mask / 2
                              if N >= mask then
                                 N = N - mask
                                 if 65535 * floor((coord_64K + (0.5 + 2^-16)) * (size - 1) / 65535) < (coord_64K - (0.5 + 2^-16)) * (size - 1) then
                                    data[idx] = data[idx] - mask
                                    data[3] = data[3] - 1
                                 else
                                    min_size = min_size or size
                                 end
                              end
                           end
                           if data[idx] < mask then
                              data[prev_idx] = data[prev_idx] + (N - idx)
                           else
                              prev_idx = idx
                           end
                           idx = N
                        end
                        data[4] = min_size
                     end
                  end
                  local variants_qty = xy_data[1][3] + xy_data[2][3]
                  local coords_processed_1 = xy_data[1][2]
                  local coords_processed_2 = xy_data[2][2]
                  if variants_qty ~= prev_variants_qty then
                     prev_variants_qty = variants_qty
                     prev_coords_processed_1 = coords_processed_1
                     prev_coords_processed_2 = coords_processed_2
                  end
                  if min(coords_processed_1 - prev_coords_processed_1, coords_processed_2 - prev_coords_processed_2) >= 20 then
                     tl.put("Determined at frame "..frame..", resolution: "..xy_data[1][4].." x "..xy_data[2][4])
                     trust = true
                     break
                  end
                  local num = sqrt(frame + 0.1) % 1 < 0.5 and 2^13 or 0
                  MoveMouseRelative(
                     dx * max(1, floor(num / ((xy_64K[1] - 2^15) * dx + (2^15 + 2^13/8)))),
                     dy * max(1, floor(num / ((xy_64K[2] - 2^15) * dy + (2^15 + 2^13/8))))
                  )
                  tl.wait(10)
                  xy_64K[1], xy_64K[2] = GetMousePosition()
               end
               if not trust then
                  xy_data[1][4], xy_data[2][4] = nil
               end
            end
         end
         enabled = false
         print'Function "GetMousePositionInPixels()" failed to determine screen resolution and has been disabled'
      end
      return 0, 0, 0, 0, xy_64K[1], xy_64K[2]  -- functionality is disabled, so no pixel-related information is returned
   end

end

 function SetMousePositionInPixels(x, y)
   local _, _, width, height = GetMousePositionInPixels()
   if width > 0 then
      MoveMouseTo(
         floor(max(0, min(width  - 1, x)) * (2^16-1) / (width  - 1) + 0.5),
         floor(max(0, min(height - 1, y)) * (2^16-1) / (height - 1) + 0.5)
      )
   end
end