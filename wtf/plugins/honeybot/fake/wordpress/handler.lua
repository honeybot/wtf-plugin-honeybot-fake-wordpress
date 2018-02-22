local require = require
local tools = require("wtf.core.tools")
local Plugin = require("wtf.core.classes.plugin")
local lfs = require("lfs")
local cjson = require("cjson")

local _M = Plugin:extend()
_M.name = "honeybot.fake.wordpress"

function send_response(state,headers,content)
    ngx.ctx.response_from_lua = 1
    ngx.status = state
    if headers then
        for key,val in pairs(headers) do
            ngx.header[key] = val
        end
    end
    ngx.print(content)
    ngx.exit(ngx.HTTP_OK)
end

function _M:access(...)
    local select = select
    local instance = select(1, ...)
    local version = self:get_optional_parameter('version')
    local path = self:get_optional_parameter('path')
    local filename = path .. version .. "/" ..ngx.var.uri
    local get,post,files = require("resty.reqargs")()
    local headers = {}
    local files = cjson.decode(io.open(path.."files.json","rb"):read "*a")
    local dirs = cjson.decode(io.open(path.."dirs.json","rb"):read "*a")
    ngx.req.set_header("Accept-Encoding", "")

    if files[ngx.var.uri] then
        for md5,versions in pairs(files[ngx.var.uri]) do
            if versions[version] then
                local page = io.open(path .. "content/" .. tostring(md5), "rb"):read "*a"
                send_response(200, {["Content-Type"]="text/html"}, page)
            end
        end
        send_response(404, {["Content-Type"]="text/html"}, "")
    end

    if dirs[string.gsub(ngx.var.uri,"/?$","")] then
        if dirs[string.gsub(ngx.var.uri,"/?$","")][version] then
            send_response(403, {["Content-Type"]="text/html"}, "")
        end
    end

    if get["action"] == "register" then
        send_response(301,{["Location"]="/wp-login.php?registration=disabled"},"")
    end

    if  ngx.var.uri == "/wp-links-opml.php"
        or ngx.var.uri == "/wp-login.php" then
            local page = io.open(path .. "content" .. ngx.var.uri):read "*a"
            page = string.gsub(page, "__VERSION__", version)
            send_response(200, {["Content-Type"]="text/xml; charset=UTF-8"}, page)
    elseif ngx.var.uri == "/wp-signup.php" then
        send_response(301,{["Location"]="/wp-login.php?action=register"},"")
    end

    local link_type, link_name, link_path = string.match(ngx.var.uri, "wp.content/([^/]*)/([^/]*)/?(.*)$")
    if link_type == "themes" or link_type == "plugins" then
        if link_path == "readme.txt"
            or link_path == "changelog.txt"
            or link_path == "error_log"
            or link_path == "style.css" then
                send_response(200, {["Content-Type"]="text/html"}, "Version: 1.0.0")
        end
        local temp = string.gsub(link_path,"^.*/([^/]*)$", "%1")
        if  temp == "thumb.php"
            or temp == "timthumb.php" then
                send_response(200, {["Content-Type"]="text/html"}, "<pre>no image specified<br />Query String : <br />TimThumb version : 1.16</pre>")
        end
        if link_path == "" then
            send_response(200, {["Content-Type"]="text/plain"}, "")
        end
    end

	return self
end

function _M:header_filter(...)
    ngx.header.content_length = nil 
end

function _M:body_filter(...)
    local select = select
    local instance = select(1, ...)
    local version = self:get_optional_parameter('version')
    local path = self:get_optional_parameter('path')

    if not ngx.ctx.response_from_lua then
        ngx.arg[1] = ngx.re.gsub(ngx.arg[1],'<meta name="generator" content="Wordpress[^>]*>', "")
        ngx.arg[1] = ngx.re.gsub(ngx.arg[1],'<head>', '<head>\n<meta name="generator" content="WordPress '.. version .. '" />\n<!--\n/wp-content/themes/twentyfourteen/\n/wp-content/plugins/theme-my-login/style.css\n-->')
    end
    return self
end

return _M

