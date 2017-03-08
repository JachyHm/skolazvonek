headerBlock = "\r\nContent-type: text/html\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache\r\n\r\n"
local currentFileName = ""
local isPostData = false
print("filexfer")
local srv=net.createServer(net.TCP, 60) 
srv:listen(80,
    function(conn) 
        local function writefile(name, mode, data)
            if (file.open("temp_" .. name, mode) == nil) then
                return -1
            end
            file.write(data)
            file.close()
        end
        conn:on("disconnection", 
            function(conn) 
                isPostData = false
            end
        )
        conn:on("sent", 
            function(conn) 
                currentFileName = ""
                isPostData = false
                conn:close()
            end
        )
        conn:on("receive",
            function(conn, payload)
                tmr.wdclr();
                local s, e, m, buf, k, v
                local tbl = {}
                local i = 1
                local retval = ""

                if isPostData then
                    writefile(currentFileName, "a+", payload)
                else
                    s, e = string.find(payload, "HTTP", 1, true)
                    if e ~= nil then
                        buf = string.sub(payload, 1, s - 2)
                        for m in string.gmatch(buf, "/?([%w+%p+][^/+]*)") do
                            tbl[i] = m
                            i = i + 1
                        end
                        m = nil
                        if #tbl > 2 then
                            local cmd = tbl[2]
                            if (tbl[3] ~= nil) and (tbl[3] ~= "/") then
                                currentFileName = tbl[3]
                            --else return an error
                            end

                            if (cmd == "put") then
                                writefile(currentFileName, "w+", "")
                            end

                            if (cmd == "append") then
                                isPostData = true
                            end

                            if (cmd == "persist") then
                                file.rename("temp_" .. currentFileName, currentFileName)
                            end

                            buf = ""
                            if retval == nil then
                                retval = "[nil]"
                            end
                            buf = "HTTP/1.1 200 OK" .. headerBlock .. retval
                        else
                            local filename = "index.html"
                            if tbl[2] ~= nil and tbl[2] ~= "/" then
                                filename = tbl[2]
                            end
                            require("fileupload")(conn, filename)
                            buf = ""
                        end
                        conn:send(buf)
                    end
                end
            end
        ) 
    end
)