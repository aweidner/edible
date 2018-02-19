local parser = {}

local function result(success, remaining, matched)
    -- Create a new result object with standard fields
    return {success = success, rem = remaining, matched = matched}
end

local function inherit_fields(original_result, other_result)
    -- Copy any fields not in the original_result table from
    -- other_result.  This copy is done in place, no result
    -- is returned
    for key, value in pairs(other_result) do
        if original_result[key] == nil then
            original_result[key] = value
        end
    end
end

local function append_matched(matched, match_result)
    -- Append the matched items from match_result to matched
    -- and return the remaining string to parse from match_result.
    --
    -- This is extracted out as a function because the same operation
    -- is being done multiple times in some of the smaller parsers.
    return matched .. match_result.matched, match_result.rem
end

local function save_as(matcher, field, from_field)
    -- In order to enable getting the data out of a string,
    -- we want to save it to a particular field.  For example if
    -- we parse a column definition we may want to save the name
    -- of the column and the type.  This function allows
    -- extracting the matched result from a parser and saving it
    -- to a specific field.
    --
    -- By default, the matched result will be pulled from
    -- the "matched" field in the result table.  Passing in
    -- a value to from_field overrides this, and is intended
    -- to work with cases where we are already saving the results
    -- of some other field and we want to pass it up the chain or
    -- pass it up as a different field name.
    from_field = from_field or "matched"
    return function(text)
        local match_result = matcher(text)
        match_result[field] = match_result[from_field]
        return match_result
    end
end

function parser.match_pattern(text, look_for)
    -- Use the built in Lua pattern matching to match
    -- a string.  This is the basis for all parsers.  The
    -- smallest parser that does something useful.
    local matched = text:match(look_for)

    if matched then
        return result(true, text:sub(#matched + 1, #text), matched)
    end
    return result(false, text, "")
end

function parser.pattern(pattern)
    -- When parsing through a string by patterns, we want to match
    -- at the start of a string.  This is because our parsers are composed
    -- of chains of smaller parsers all relying on patterns.  After
    -- a section of the string to parse is consumed, the next parser
    -- needs to match at the beginning of the string.
    --
    -- The purpose of this parser is to use the pattern matching function
    -- and always append "^" to the pattern passed in so that it can be left
    -- out.  It's implicitly required, so always append it.
    --
    -- All parsers should also return functions that take one argument, the
    -- text to parse.  We wrap the pattern matching function in this way.
    return function(text)
        return parser.match_pattern(text, "^" .. pattern)
    end
end

function parser.any_of(matchers)
    -- Take a list of parsers and return successfully if any
    -- of them match the input string.  Each parser will be tested
    -- in order of appearance and the first one to match will
    -- be selected.
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

function parser.compose(matchers)
    -- Compose multiple parsers together in order.  Each will be used
    -- in order to consume the input string.  The result of the application
    -- of each parser is returned.
    return function(text)
        local final_result = result(true, text, "")

        for _, matcher in pairs(matchers) do
            local match_result = matcher(final_result.rem)

            -- Return on the first error
            if not match_result.success then
                final_result.success = false
                return final_result
            end

            -- Otherwise add to match and subtract the matched part from
            -- the remaining string to parse
            final_result.matched, final_result.rem = append_matched(
                final_result.matched, match_result)

            -- Copy over any fields that might have been saved in the other
            -- parsers.
            --
            -- ASSUMPTION: Parsers will not have name collisions in their
            -- saved fields.  If they do, the later ones will overwrite
            -- fields from the earlier ones
            inherit_fields(final_result, match_result)
        end

        return final_result
    end
end

function parser.one_or_more_of(matcher, optional_next)
    -- Requires that text pass through the parser at least time.  The
    -- text may or may not pass through the parser additional times but
    -- if it does, the instances that match the parser must be separated
    -- by a string matching `optional_next`
    return function(text)
        local results = {}
        local remaining = text
        local matched_so_far = ""

        -- Apply the parser once.  If it doesn't match then
        -- there's no reason to do anything else.
        local match_result = matcher(remaining)
        if not match_result.success then
            return match_result
        end

        -- And save the result
        matched_so_far, remaining = append_matched(matched_so_far, match_result)
        table.insert(results, match_result)

        while match_result.success do

            -- Attempt to match the separator.  If it doesn't match then there is
            -- no more we can parse as part of this parser.  Break out of the loop.
            local has_more = optional_next(remaining)
            if not has_more.success then
                break
            end

            -- Append the matched result of parsing the separator.  This is necessary
            -- because other parsers later in the parsing may depend on having
            -- the entire string saved in `matched` so they can determine what is
            -- left to parse accurately.  This is purely a bookkeeping operation.
            matched_so_far, remaining = append_matched(matched_so_far, has_more)

            -- Parse the next substantial part and add it to results
            match_result = matcher(remaining)
            matched_so_far, remaining = append_matched(matched_so_far, match_result)
            table.insert(results, match_result)
        end

        -- Append the entire set of match results for the substantial (non-separator parts)
        -- into a field called `parts`
        local final_result = result(true, remaining, matched_so_far)
        final_result.parts = results

        return final_result
    end
end

local function to_string(matcher, field)
    -- Cast result in field to string (remove quotes)
    return function(text)
        local match_result = matcher(text)
        match_result[field] = match_result[field]:sub(2, #match_result[field] - 1)
        return match_result
    end
end

local function to_int(matcher, field)
    -- Cast result in field to int
    return function(text)
        local match_result = matcher(text)
        match_result[field] = tonumber(match_result[field])
        return match_result
    end
end

local function to_nil(matcher, field)
    -- Set the result in a field to nil
    return function(text)
        local match_result = matcher(text)
        match_result[field] = nil
        return match_result
    end
end

local identifier = parser.pattern("[a-zA-Z_0-9]+")
local value = parser.any_of({
    to_string(save_as(parser.pattern("'[^']*'"), "value"), "value"),
    to_int(save_as(parser.pattern("[0-9]+"), "value"), "value"),
    to_nil(save_as(parser.pattern("NULL"), "value"), "value")
})
local comma_seperator = parser.pattern("%s*,%s*")
local whitespace = parser.pattern("%s*")
local open_paren = parser.pattern("%(")
local closed_paren = parser.pattern("%)")

local function allow_whitespace(matchers)
    -- Transform a list of parsers into a list of
    -- parsers that will accept whitespace between all other
    -- parsers.  This makes it more convenient to write long chains
    -- of compose parsers since the whitespace allowance becomes
    -- implicit
    local result_matchers = {whitespace}

    for _, v in pairs(matchers) do
        table.insert(result_matchers, v)
        table.insert(result_matchers, whitespace)
    end
    return result_matchers
end

parser.types = save_as(parser.any_of({parser.pattern("int"), parser.pattern("string")}), "type")
parser.column_name = save_as(identifier, "name")
parser.column_def = parser.compose({parser.column_name, parser.pattern("%s+"), parser.types})
parser.columns = save_as(parser.one_or_more_of(parser.column_def, comma_seperator), "columns", "parts")
parser.column_names = save_as(parser.one_or_more_of(parser.column_name, comma_seperator),
    "columns", "parts")
parser.values = save_as(parser.one_or_more_of(value, comma_seperator), "values", "parts")

local function paren_wrap(matcher)
    -- Utility function to make working with paren wrapped matchers a little
    -- easier
    return parser.compose({open_paren, matcher, closed_paren})
end

parser.table_name = save_as(identifier, "table_name")

parser.create_table = parser.compose(allow_whitespace({
    parser.pattern("CREATE TABLE"),
    parser.table_name,
    paren_wrap(parser.columns)
}))

parser.insert = parser.compose(allow_whitespace({
    parser.pattern("INSERT INTO"),
    parser.table_name,
    paren_wrap(parser.column_names),
    parser.pattern("VALUES"),
    paren_wrap(parser.values)
}))

return parser
