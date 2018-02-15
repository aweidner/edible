local parser = {}

local function result(success, remaining, matched)
    return {success = success, rem = remaining, matched = matched}
end

function parser.match_pattern(text, look_for)
    local matched = text:match(look_for)

    if matched then
        return result(true, text:sub(#matched + 1, #text), matched)
    end
    return result(false, text, "")
end

function parser.pattern(pattern)
    return function(text)
        return parser.match_pattern(text, "^" .. pattern)
    end
end

function parser.anyOf(matchers)
    return function(text)
        for _, matcher in pairs(matchers) do
            local match_results = matcher(text)
            if match_results.success then
                return match_results
            end
        end

        return result(false, text, "")
    end
end

function parser.compose(matchers)
    return function(text)
        local remaining = text
        local matched = ""

        for _, matcher in pairs(matchers) do
            local match_results = matcher(remaining)

            if not match_results.success then
                return result(false, remaining, matched)
            end

            matched = matched .. match_results.matched
            remaining = match_results.rem
        end

        return result(true, remaining, matched)
    end
end


parser.types = parser.anyOf({parser.pattern("int"), parser.pattern("string")})
parser.column_def = parser.compose({
    parser.pattern("[a-zA-Z_]+"),
    parser.pattern("%s+"), parser.types})

return parser
