local parser = {}

local function result(success, remaining)
    return {success = success, rem = remaining}
end

function parser.match_pattern(text, look_for)
    local matched = text:match(look_for)

    if matched then
        return result(true, text:sub(#matched + 1, #text))
    end
    return result(false, text)
end

return parser
