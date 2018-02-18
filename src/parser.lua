local parser = {}

local function result(success, remaining, matched)
    return {success = success, rem = remaining, matched = matched}
end

local function inherit_fields(original_result, other_result)
    for key, value in pairs(other_result) do
        if original_result[key] == nil then
            original_result[key] = value
        end
    end
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
            local match_result = matcher(text)
            if match_result.success then
                return match_result
            end
        end

        return result(false, text, "")
    end
end

local function remove_matched(matched, match_result)
    return matched .. match_result.matched, match_result.rem
end

local function saveAs(matcher, field, from_field)
    from_field = from_field or "matched"
    return function(text)
        local match_result = matcher(text)
        match_result[field] = match_result[from_field]
        return match_result
    end
end

function parser.compose(matchers)
    return function(text)
        local final_result = result(true, text, "")

        for _, matcher in pairs(matchers) do
            local match_result = matcher(final_result.rem)

            if not match_result.success then
                final_result.success = false
                return final_result
            end

            final_result.matched, final_result.rem = remove_matched(
                final_result.matched, match_result)

            inherit_fields(final_result, match_result)
        end

        return final_result
    end
end

function parser.oneOrMoreOf(matcher, optional_next)
    return function(text)
        local results = {}
        local remaining = text
        local matched_so_far = ""

        local match_result = matcher(remaining)
        if not match_result.success then
            return match_result
        end

        matched_so_far, remaining = remove_matched(matched_so_far, match_result)
        table.insert(results, match_result)

        while match_result.success do
            local has_more = optional_next(remaining)
            if not has_more.success then
                break
            end
            matched_so_far, remaining = remove_matched(matched_so_far, has_more)

            match_result = matcher(remaining)
            matched_so_far, remaining = remove_matched(matched_so_far, match_result)
            table.insert(results, match_result)
        end

        local final_result = result(true, remaining, matched_so_far)
        final_result.parts = results

        return final_result
    end
end


parser.whitespace = parser.pattern("%s*")
parser.types = saveAs(parser.anyOf({parser.pattern("int"), parser.pattern("string")}),"type")
parser.column_name = saveAs(parser.pattern("[a-zA-Z_0-9]+"), "name")
parser.column_def = parser.compose({parser.column_name, parser.pattern("%s+"), parser.types})
parser.columns = parser.oneOrMoreOf(parser.column_def, parser.pattern("%s*,%s*"))
parser.create_table = parser.compose({
    parser.pattern("CREATE TABLE"),
    parser.whitespace,
    saveAs(parser.pattern("[a-zA-Z_0-9]+"), "table_name"),
    parser.whitespace,
    parser.pattern("%("),
    parser.whitespace,
    saveAs(parser.columns, "columns", "parts"),
    parser.pattern("%)"),
    parser.whitespace})

return parser
