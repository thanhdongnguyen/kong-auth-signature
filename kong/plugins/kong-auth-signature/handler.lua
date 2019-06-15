local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"
local multipart = require "multipart"
local json = require "json"
local cjson = require "cjson.safe"

local Auth = BasePlugin:extend()
local kong = kong
local ipairs = ipairs
local pairs = pairs
local string = string
local type = type
local ngx = ngx
local concat = table.concat
local insert = table.insert
local find = string.find
local type = type
local sub = string.sub
local gsub = string.gsub
local match = string.match
local lower = string.lower

Auth.VERSION = "0.1.0-3"
Auth.PRIORITY = 999

function Auth:new()
    Auth.super.new(self, "kong-auth-signature")
end


function isExist(listMethod, method)

    for _, v in ipairs(listMethod) do
        if string.lower(v) == string.lower(method) then
            return true
        end
    end
    return false
end


local function sha256(msg)
    local function band(int1, int2, int3, ...)
            int1 = int1 % 2^32
            int2 = int2 % 2^32
            local ret =
            ((int1%0x00000002>=0x00000001 and int2%0x00000002>=0x00000001 and 0x00000001) or 0)+
            ((int1%0x00000004>=0x00000002 and int2%0x00000004>=0x00000002 and 0x00000002) or 0)+
            ((int1%0x00000008>=0x00000004 and int2%0x00000008>=0x00000004 and 0x00000004) or 0)+
            ((int1%0x00000010>=0x00000008 and int2%0x00000010>=0x00000008 and 0x00000008) or 0)+
            ((int1%0x00000020>=0x00000010 and int2%0x00000020>=0x00000010 and 0x00000010) or 0)+
            ((int1%0x00000040>=0x00000020 and int2%0x00000040>=0x00000020 and 0x00000020) or 0)+
            ((int1%0x00000080>=0x00000040 and int2%0x00000080>=0x00000040 and 0x00000040) or 0)+
            ((int1%0x00000100>=0x00000080 and int2%0x00000100>=0x00000080 and 0x00000080) or 0)+
            ((int1%0x00000200>=0x00000100 and int2%0x00000200>=0x00000100 and 0x00000100) or 0)+
            ((int1%0x00000400>=0x00000200 and int2%0x00000400>=0x00000200 and 0x00000200) or 0)+
            ((int1%0x00000800>=0x00000400 and int2%0x00000800>=0x00000400 and 0x00000400) or 0)+
            ((int1%0x00001000>=0x00000800 and int2%0x00001000>=0x00000800 and 0x00000800) or 0)+
            ((int1%0x00002000>=0x00001000 and int2%0x00002000>=0x00001000 and 0x00001000) or 0)+
            ((int1%0x00004000>=0x00002000 and int2%0x00004000>=0x00002000 and 0x00002000) or 0)+
            ((int1%0x00008000>=0x00004000 and int2%0x00008000>=0x00004000 and 0x00004000) or 0)+
            ((int1%0x00010000>=0x00008000 and int2%0x00010000>=0x00008000 and 0x00008000) or 0)+
            ((int1%0x00020000>=0x00010000 and int2%0x00020000>=0x00010000 and 0x00010000) or 0)+
            ((int1%0x00040000>=0x00020000 and int2%0x00040000>=0x00020000 and 0x00020000) or 0)+
            ((int1%0x00080000>=0x00040000 and int2%0x00080000>=0x00040000 and 0x00040000) or 0)+
            ((int1%0x00100000>=0x00080000 and int2%0x00100000>=0x00080000 and 0x00080000) or 0)+
            ((int1%0x00200000>=0x00100000 and int2%0x00200000>=0x00100000 and 0x00100000) or 0)+
            ((int1%0x00400000>=0x00200000 and int2%0x00400000>=0x00200000 and 0x00200000) or 0)+
            ((int1%0x00800000>=0x00400000 and int2%0x00800000>=0x00400000 and 0x00400000) or 0)+
            ((int1%0x01000000>=0x00800000 and int2%0x01000000>=0x00800000 and 0x00800000) or 0)+
            ((int1%0x02000000>=0x01000000 and int2%0x02000000>=0x01000000 and 0x01000000) or 0)+
            ((int1%0x04000000>=0x02000000 and int2%0x04000000>=0x02000000 and 0x02000000) or 0)+
            ((int1%0x08000000>=0x04000000 and int2%0x08000000>=0x04000000 and 0x04000000) or 0)+
            ((int1%0x10000000>=0x08000000 and int2%0x10000000>=0x08000000 and 0x08000000) or 0)+
            ((int1%0x20000000>=0x10000000 and int2%0x20000000>=0x10000000 and 0x10000000) or 0)+
            ((int1%0x40000000>=0x20000000 and int2%0x40000000>=0x20000000 and 0x20000000) or 0)+
            ((int1%0x80000000>=0x40000000 and int2%0x80000000>=0x40000000 and 0x40000000) or 0)+
            ((int1>=0x80000000 and int2>=0x80000000 and 0x80000000) or 0)

            return (int3 and band(ret, int3, ...)) or ret
    end

    local function bxor(int1, int2, int3, ...)
            local ret =
            ((int1%0x00000002>=0x00000001 ~= (int2%0x00000002>=0x00000001) and 0x00000001) or 0)+
            ((int1%0x00000004>=0x00000002 ~= (int2%0x00000004>=0x00000002) and 0x00000002) or 0)+
            ((int1%0x00000008>=0x00000004 ~= (int2%0x00000008>=0x00000004) and 0x00000004) or 0)+
            ((int1%0x00000010>=0x00000008 ~= (int2%0x00000010>=0x00000008) and 0x00000008) or 0)+
            ((int1%0x00000020>=0x00000010 ~= (int2%0x00000020>=0x00000010) and 0x00000010) or 0)+
            ((int1%0x00000040>=0x00000020 ~= (int2%0x00000040>=0x00000020) and 0x00000020) or 0)+
            ((int1%0x00000080>=0x00000040 ~= (int2%0x00000080>=0x00000040) and 0x00000040) or 0)+
            ((int1%0x00000100>=0x00000080 ~= (int2%0x00000100>=0x00000080) and 0x00000080) or 0)+
            ((int1%0x00000200>=0x00000100 ~= (int2%0x00000200>=0x00000100) and 0x00000100) or 0)+
            ((int1%0x00000400>=0x00000200 ~= (int2%0x00000400>=0x00000200) and 0x00000200) or 0)+
            ((int1%0x00000800>=0x00000400 ~= (int2%0x00000800>=0x00000400) and 0x00000400) or 0)+
            ((int1%0x00001000>=0x00000800 ~= (int2%0x00001000>=0x00000800) and 0x00000800) or 0)+
            ((int1%0x00002000>=0x00001000 ~= (int2%0x00002000>=0x00001000) and 0x00001000) or 0)+
            ((int1%0x00004000>=0x00002000 ~= (int2%0x00004000>=0x00002000) and 0x00002000) or 0)+
            ((int1%0x00008000>=0x00004000 ~= (int2%0x00008000>=0x00004000) and 0x00004000) or 0)+
            ((int1%0x00010000>=0x00008000 ~= (int2%0x00010000>=0x00008000) and 0x00008000) or 0)+
            ((int1%0x00020000>=0x00010000 ~= (int2%0x00020000>=0x00010000) and 0x00010000) or 0)+
            ((int1%0x00040000>=0x00020000 ~= (int2%0x00040000>=0x00020000) and 0x00020000) or 0)+
            ((int1%0x00080000>=0x00040000 ~= (int2%0x00080000>=0x00040000) and 0x00040000) or 0)+
            ((int1%0x00100000>=0x00080000 ~= (int2%0x00100000>=0x00080000) and 0x00080000) or 0)+
            ((int1%0x00200000>=0x00100000 ~= (int2%0x00200000>=0x00100000) and 0x00100000) or 0)+
            ((int1%0x00400000>=0x00200000 ~= (int2%0x00400000>=0x00200000) and 0x00200000) or 0)+
            ((int1%0x00800000>=0x00400000 ~= (int2%0x00800000>=0x00400000) and 0x00400000) or 0)+
            ((int1%0x01000000>=0x00800000 ~= (int2%0x01000000>=0x00800000) and 0x00800000) or 0)+
            ((int1%0x02000000>=0x01000000 ~= (int2%0x02000000>=0x01000000) and 0x01000000) or 0)+
            ((int1%0x04000000>=0x02000000 ~= (int2%0x04000000>=0x02000000) and 0x02000000) or 0)+
            ((int1%0x08000000>=0x04000000 ~= (int2%0x08000000>=0x04000000) and 0x04000000) or 0)+
            ((int1%0x10000000>=0x08000000 ~= (int2%0x10000000>=0x08000000) and 0x08000000) or 0)+
            ((int1%0x20000000>=0x10000000 ~= (int2%0x20000000>=0x10000000) and 0x10000000) or 0)+
            ((int1%0x40000000>=0x20000000 ~= (int2%0x40000000>=0x20000000) and 0x20000000) or 0)+
            ((int1%0x80000000>=0x40000000 ~= (int2%0x80000000>=0x40000000) and 0x40000000) or 0)+
            ((int1>=0x80000000 ~= (int2>=0x80000000) and 0x80000000) or 0)

            return (int3 and bxor(ret, int3, ...)) or ret
    end

    local function bnot(int)
            return 4294967295 - int
    end

    local function rshift(int, by)
            int = int % 2^32
            local shifted = int / (2 ^ by)
            return shifted - shifted % 1
    end

    local function rrotate(int, by)
            int = int % 2^32
            local shifted = int / (2 ^ by)
            local fraction = shifted % 1
            return (shifted - fraction) + fraction * (2 ^ 32)
    end

    local k = {
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
            0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
            0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
            0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
            0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
            0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
            0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
            0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
            0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }


    local function str2hexa(s)
            local h = string.gsub(s, ".", function(c)
                    return string.format("%02x", string.byte(c))
            end)
            return h
    end

    local function num2s(l, n)
            local s = ""
            for i = 1, n do
                    local rem = l % 256
                    s = string.char(rem) .. s
                    l = (l - rem) / 256
            end
            return s
    end

    local function s232num(s, i)
            local n = 0
            for i = i, i + 3 do n = n*256 + string.byte(s, i) end
            return n
    end

    local function preproc(msg, len)
            local extra = 64 - ((len + 1 + 8) % 64)
            len = num2s(8 * len, 8)
            msg = msg .. "\128" .. string.rep("\0", extra) .. len
            return msg
    end

    local function initH256(H)
            H[1] = 0x6a09e667
            H[2] = 0xbb67ae85
            H[3] = 0x3c6ef372
            H[4] = 0xa54ff53a
            H[5] = 0x510e527f
            H[6] = 0x9b05688c
            H[7] = 0x1f83d9ab
            H[8] = 0x5be0cd19
            return H
    end

    local function digestblock(msg, i, H)
            local w = {}
            for j = 1, 16 do w[j] = s232num(msg, i + (j - 1) * 4) end
            for j = 17, 64 do
                    local v = w[j - 15]
                    local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
                    v = w[j - 2]
                    local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
                    w[j] = w[j - 16] + s0 + w[j - 7] + s1
            end

            local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
            for i = 1, 64 do
                    local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                    local maj = bxor(band(a, b), band(a, c), band(b, c))
                    local t2 = s0 + maj
                    local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                    local ch = bxor (band(e, f), band(bnot(e), g))
                    local t1 = h + s1 + ch + k[i] + w[i]
                    h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
            end

            H[1] = (H[1] + a) % 2^32
            H[2] = (H[2] + b) % 2^32
            H[3] = (H[3] + c) % 2^32
            H[4] = (H[4] + d) % 2^32
            H[5] = (H[5] + e) % 2^32
            H[6] = (H[6] + f) % 2^32
            H[7] = (H[7] + g) % 2^32
            H[8] = (H[8] + h) % 2^32
    end

    msg = preproc(msg, #msg)
    local H = initH256({})
    for i = 1, #msg, 64 do digestblock(msg, i, H) end
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
            num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end



function parseBody(conf)

    local method = string.lower(kong.request.get_method())
    local args = {}


    if method == "get" then
        local query, err = kong.request.get_query()


        if err then
            return {}, {status = 500, message = "not found params"}
        else
            args = query
        end
    elseif method == "post" then
        local body, err, mimetype = kong.request.get_body()

        if err then
            return {}, {status = 500, message = "not found params"}
        else

            if mimetype == "application/x-www-form-urlencoded" then
                args = body
            elseif mimetype == "application/json" then
                args = json.decode(kong.request.get_raw_body())
            elseif mimetype == "multipart/form-data" then
                args = multipart(kong.request.get_raw_body(), kong.request.get_header("Content-Type")):get_all()
            else
                return {}, {status = 500, message = "not found params"}
            end
        end
    end
    return args, nil
end


function sortKey( args, conf )
    local index = {}
    local result = {}

    for _,v in pairs(args) do

        if string.lower(conf.body_key) ~= string.lower(_) then
            table.insert(index, _)
        end

    end



    table.sort( args )


    for _, v in pairs(index) do
        table.insert( result, args[v] )
    end

    return result
end

function createSignature(key, args, conf)

    local queryString = ""
    local sargs = sortKey(args, conf)
    for _, v in pairs(sargs) do
        queryString = queryString .. v
    end

    -- return sargs
    return sha256(queryString..key)
end


local function read_json_body(body)
    if body then
      return cjson.decode(body)
    end
end

function transform_json_body(conf, buffered_data)
    local json_body = read_json_body(buffered_data)
    if json_body == nil then
      return cjson.encode({
            error = {
                code = 400,
                message = "401 Unauthorized"
            }
        })
    end


    if json_body["message"] and json_body["status"] then
        return cjson.encode({
            error = {
                code = json_body["status"],
                message = json_body["message"]
            }
        })
    end

    if json_body["message"] then
        return cjson.encode({
            error = {
                code = 500,
                message = json_body["message"]
            }
        })
    end
    return cjson.encode(json_body)
end

function is_json_body(content_type)
    return content_type and find(lower(content_type), "application/json", nil, true)
end

function doAuthenticationSignature(conf)

    if not conf.header_key or not conf.body_key then
        return false, {status = 401, message = "401 Unauthorized"}
    end

    local api_key = kong.request.get_header(conf.header_key)
    local body, err = parseBody(conf)


    if err or not api_key or not body[conf.body_key] then
        return false, {status = 400, message = "400 Bad Request"}
    end

    if not conf.api_key_1 and not conf.api_key_2 and not conf.api_key_3 and not conf.api_key_4 and not conf.api_key_5 then
        return false, { status = 400, message = "400 Bad Request" }
    end

    local secret_key = ""
    if conf.api_key_2 == api_key then
        secret_key = conf.secret_key_2
    elseif conf.api_key_1 == api_key then
        secret_key = conf.secret_key_1
    elseif conf.api_key_3 == api_key then
        secret_key = conf.secret_key_3
    elseif conf.api_key_4 == api_key then
        secret_key = conf.secret_key_4
    elseif conf.api_key_5 == api_key then
        secret_key = conf.secret_key_5
    else
        return false, { status = 400, message = "400 Bad Request" }
    end

    local verify_sign = createSignature(secret_key, body, conf)

    kong.log("veify_sign", " | ", verify_sign, " | ", body.signature)
    if verify_sign ~= body.signature then
        return false, { status = 403, message = "403 Forbidden" }
    end

    return true, nil
end

function Auth:access(conf)

    Auth.super.access(self)
 
    
    local ok, err = doAuthenticationSignature(conf)


    if err ~= true then

        kong.log("check-signature", " | ", err.message)

        return kong.response.exit(err.status, {
            message = err.message,
            status = err.status
        })
    end

    
end

function Auth:header_filter(conf)
    Auth.super.header_filter(self)

    kong.response.clear_header("Content-Length")
end

function Auth:body_filter(conf)
    Auth.super.body_filter(self)

    if is_json_body(kong.response.get_header("Content-Type")) then
        local ctx = ngx.ctx
        local chunk, eof = ngx.arg[1], ngx.arg[2]

        ctx.rt_body_chunks = ctx.rt_body_chunks or {}
        ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

        if eof then
          local chunks = concat(ctx.rt_body_chunks)
          local body = transform_json_body(conf, chunks)

          kong.log("chunk-response", chunks)
          ngx.arg[1] = body or chunks

        else
          ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
          ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
          ngx.arg[1] = nil
        end
    end

end


return Auth