-- show_mounts : template for filesystem
-- notes : updates after every 5 conky updates
-- usage : ${lua conky_show_mounts}

cached_conky_show_mount_output = nil

function conky_show_mounts()
    local updates = tonumber(conky_parse("${updates}"))
    local interval = 5 -- number of conky updates after which this function should be updated
                       -- in seconds, this is equal to (interval * conky's update_interval)

    if (updates%interval ~= 0) and (cached_conky_show_mount_output ~= nil) then
        -- print('cached') -- uncomment to debug
        -- print(cached_conky_show_mount_output) -- uncomment to debug
        return conky_parse(cached_conky_show_mount_output)
    end

    -- Run the following lsblk command to get the device names and their mounted locations (except loop devices)
    local command = "lsblk --raw --noheadings -o NAME,MOUNTPOINT -e7 | awk '$1~/[[:digit:]]/ && $2 != \"\"' | grep -v -i 'swap'"

    -- print(command) -- Uncomment to debug

    -- Execute the command and capture the output
    local handle = io.popen(command)
    local output = handle:read("*a")
    handle:close()

    local result = "" -- The final result will be concatenated to this string

    -- Process the output in Lua
    for line in output:gmatch("[^\r\n]+") do
       local mount_name, mount_point = line:match('(%S+)%s*(%S*)')
        -- print(mount_name) -- uncomment to debug
        -- print(mount_point) -- uncomment to debug

        -- Add this mount {name, point} to result
        if mount_name and mount_point then -- our cmd also outputs devnames which don't have mountpoints; ignore them
            result = result .. "\n${color2}" .. mount_name .. " ${fs_used " .. mount_point .. "} / ${fs_size " ..
                     mount_point .. "} ${alignr}${color1}${fs_bar 10,120 " .. mount_point .. "}"
        end
    end

    -- print('reloaded') -- uncomment to debug
    cached_conky_show_mount_output = result

    return conky_parse(cached_conky_show_mount_output)
end
