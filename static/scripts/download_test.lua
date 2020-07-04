local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
    ["title"] = "白嫖自用",
    ["description"] = "pdd",
    ["version"] = "Privation",
	["color"] = "2E2EFE",
}

accelerate_url = "https://d.pcs.baidu.com/rest/2.0/pcs/file?method=locatedownload"

function onInitTask(task, user, file)
    if task:getType() ~= TASK_TYPE_SHARE_BAIDU then
        return false
    end
    --这里是需要定期更新的东西
    local yxdata1 = "&version=6.9.10.1&devuid=BDIMXV2%2DO%5F58C43A2EA3CB40E2BF64716F6D343F4F%2DC%5F0%2DD%5FAA000000000000000351%2DM%5F00E0707BD0AF%2DV%5F4DEF812F&rand=e7ee8647d3b6e6e3e781d5f71705d33ad38c8dc2&time=1593823621"
    local Cookies = "BDUSS=JwODJKM0NuaTlKc2t1eGZZLUVpT1BvODU4a0VmNDBkRElIUS1Gelg1Y0xYaWRmRVFBQUFBJCQAAAAAAQAAAAEAAAAIE4Ebwv7A8jU1OTMwNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAvR~14L0f9edH"
   --结束
    local data = ""
    local yxdata = "app_id=250528&check_blue=1&es=1&esl=1&ver=4.0&dtype=1&err_ver=1.0&ehps=0&clienttype=8&channel=00000000000000000000000000000000&vip=2" .. string.gsub(string.gsub(file.dlink, "https://d.pcs.baidu.com/file/", "&path="), "?fid", "&fid") .. yxdata1
    local header = { "User-Agent: netdisk;6.9.7.4;PC;PC-Windows;6.3.9600;WindowsBaiduYunGuanJia" }
    pd.messagebox("选择下载接口时，建议使用推荐接口，下载速度更快".."\r\n部分IP[d0]接口无法下载请改用[d6]或其他推荐接口达到满速", "提示")
    table.insert(header, "Cookie: "..Cookies)
    local c = curl.easy {
        url = accelerate_url,
        post = 1,
        postfields = yxdata,
        httpheader = header,
        timeout = 15,
        ssl_verifyhost = 0,
        ssl_verifypeer = 0,
        proxy = pd.getProxy(),
        writefunction = function(buffer)
            data = data .. buffer
            return #buffer
        end,
    }
    local _, e = c:perform()
    c:close()
    if e then
        return false
    end
    local j = json.decode(data)
    if j == nil then
        return false
    end
    local message = {}
    local downloadURL = ""
    --pd.logInfo(data)
    for i, w in ipairs(j.urls) do
        downloadURL = w.url
        local d_start = string.find(downloadURL, "//") + 2
        local d_end = string.find(downloadURL, "%.") - 1
        downloadURL = string.sub(downloadURL, d_start, d_end)
        local length = string.len(downloadURL)
        if length <= 3
        then
            if string.find(downloadURL, "d0") ~= nil
            then
                table.insert(message, downloadURL .. "(超推荐[d0部分IP无法下载用d6])")
            else
                table.insert(message, downloadURL .. "(超推荐)")
            end
        elseif length == 7
        then
            table.insert(message, downloadURL .. "(一般推荐)")
        elseif string.find(downloadURL, "cache") ~= nil
        then
            table.insert(message, downloadURL .. "(超推荐)")
        elseif string.find(downloadURL, "qdall01") ~= nil
        then
            table.insert(message, downloadURL .. "(限速接口[30kb左右])")
            --实际上就是这个账号的Cookie下废了，或者就是SVIP过期导致被限速233333333
        elseif string.find(downloadURL, "xac") ~= nil
        then
            table.insert(message, downloadURL .. "(Svip接口)")
        else
            table.insert(message, downloadURL .. "(普通)")
        end
    end
    local num = pd.choice(message, 1, "选择下载接口")
    downloadURL = j.urls[num].url
    --pd.logInfo(downloadURL)
    task:setUris(downloadURL)
    task:setOptions("user-agent", "netdisk;6.9.7.4;PC;PC-Windows;6.3.9600;WindowsBaiduYunGuanJia")
    if string.find(message[num], "推荐") == nil then
        if file.size >= 8192 then
            task:setOptions("header", "Range:bytes=4096-8191")
        end
        task:setOptions("piece-length", "2M")
        task:setOptions("allow-piece-length-change", "true")
        task:setOptions("enable-http-pipelining", "true")
    end
    return true
end