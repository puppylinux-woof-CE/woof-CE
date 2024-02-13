-- conky_show_netdevs : template for network
-- usage : see https://unix.stackexchange.com/a/768938/540879

function conky_show_netdevs()
    local netdevs_handle = io.popen("ip -o link show up | grep -v lo | awk '{print $2}' | cut -d':' -f1")
    local result = ""

    for netdev in netdevs_handle:lines() do
        result = result .. "${if_up " .. netdev .. "}${if_match ${execi 5 ip -o link show " .. netdev ..
                 " | grep -i -v 'state down' | wc -l} > 0}\n" ..
                 "IP (${color1}" .. netdev .. "${color2}): ${alignr}${addr " .. netdev .. "}\n" ..
                 "${color2}Up: ${color2}${upspeed " .. netdev .. "}/s${color1}${alignr}${upspeedgraph " .. netdev .. " 10,170}\n" ..
                 "${color2}Down: ${color2}${downspeed " .. netdev .. "}/s${color1}${alignr}${downspeedgraph " .. netdev .. " 10,170}\n" ..
                 "${color2}Total Down: ${color2}${totaldown " .. netdev .. "}${alignr}Total Up: ${totalup " .. netdev .. "}${endif}${endif}"
    end

    netdevs_handle:close()

    if result ~= "" then
        return result
    else
        return ""
    end
end
