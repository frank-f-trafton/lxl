-- PILE StringProc
-- VERSION: 2.101
-- https://github.com/frank-f-trafton/pile_base


--[[
MIT License

Copyright (c) 2024 - 2026 PILE Contributors

LUIGI code: Copyright (c) 2015 airstruck
  https://github.com/airstruck/luigi

lume code: Copyright (c) 2020 rxi
  https://github.com/rxi/lume

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")
local pStringWalk = require(PATH .. "pile_string_walk")


local _assertType = pAssert.type


M.lang = {
	check_symbol_k_bad_type = "bad type for symbol key (expected string, got $1)",
	check_symbol_v_bad_type = "bad type for symbol value $1 (expected string, number, function, or true; got $2)",
	check_word_bad_value = "depth $1 index $2: bad value: $3 (type: $4)",
	check_word_missing_sym = "depth $1 index $2: missing symbol for word: $3",
	err_bad_lookup = "symbold ID: $1: bad lookup value (expected table, number, string, true, got $2)",
	err_bad_return = "bad value for returned chunk (expected true, string or table-of-strings, got $1)",
	err_no_lookup = "no lookup value for ID: $1",
	err_invalid_tok = "invalid or missing token.",
	err_max_iters = "StringProc: max iterations exceeded.",
	err_miss_q1 = "no closing (') for string literal.",
	err_miss_q2 = "no closing (\") for string literal.",
	err_no_empty_str = "empty string literals are not allowed.",
	err_trail_alt1 = "trailing alternate token at end of syntax table.",
	err_trail_alt2 = "trailing alternate (|) token without any following tokens.",
	err_unbal_paren = "unbalanced parentheses.",
	err_unexpected_alt = "unexpected 'alternative' token: $1",
	err_unexpected_rep = "unexpected repeat-token: $1"
}
local lang = M.lang


M._iter = math.huge


-- Internal use
local W_int
local t_reps, t_post = {["?"]="?",["*"]="*",["+"]="+"}, {["|"]="|"}
local tos = tostring
local _depth = 0


local function _getAlt(t, i)
	while i < #t do
		if t[i] == "|" then
			if i == #t then
				error(lang.err_trail_alt1)
			end
			return i
		end
		i = i + 1
	end
end


local function _checkEmptyStrLit(W, s)
	W:assert(#s > 0, lang.err_no_empty_str)
end


local function _toTable(W, _depth)
	local t = {}

	local alternate = false
	local close_paren = false

	W:ws()

	while not W:isEOS() do
		local str = W:match("^(['\"%(%)])") or W:match("^([a-zA-Z0-9_]+)")
		if str == ")" then
			if _depth == 1 then
				W:error(lang.err_unbal_paren)
			end
			close_paren = true
			break

		elseif str == "(" then
			t[#t + 1] = _toTable(W, _depth + 1)

		elseif str == "'" then
			t[#t + 1] = "'" .. W:matchReq("^([^']*')", lang.err_miss_q1)
			_checkEmptyStrLit(W, t[#t])

		elseif str == "\"" then
			t[#t + 1] = "\"" .. W:matchReq("^([^\"]*\")", lang.err_miss_q2)
			_checkEmptyStrLit(W, t[#t])

		-- word
		elseif str then
			t[#t + 1] = str

		else
			local ch = W:peek()
			if t_reps[ch] then
				W:error(interp(lang.err_unexpected_rep, ch))

			elseif t_post[ch] then
				W:error(interp(lang.err_unexpected_alt, ch))
			end
			W:error(lang.err_invalid_tok)
		end

		W:ws()
		local rep = W:match("^([%?%*%+])")
		if rep then
			t[#t + 1] = rep
		end

		alternate = false

		W:ws()
		str = W:match("^(|)")
		if str == "|" then
			alternate = true
			t[#t + 1] = "|"
		end
		W:ws()
	end

	if _depth > 1 and not close_paren then
		W:error(lang.err_unbal_paren)

	elseif alternate then
		W:error(lang.err_trail_alt2)
	end

	return t
end


function M.toTable(s)
	_assertType(1, s, "string")

	W_int = W_int or pStringWalk.new()
	local W = W_int
	W:setByteMode(true)
	W:setTerseMode(false)
	W:setString(s)
	W:ws()

	local ret = _toTable(W, 1)
	W:setString("")

	return ret
end


local function _traverse(W, t, symbols, state)

	_depth = _depth + 1
	-- [[DBG1]] print("(" .. _depth .. ") _traverse(): Start.")
	local ret = {}

	local orig_wi = W.I
	local n_reps = 0

	local i = 1
	while i <= #t do
		M._iter = M._iter - 1
		if M._iter < 0 then
			W:error(lang.err_max_iters)
		end

		local old_i = i
		local token = t[i]
		i = i + 1

		-- [[DBG1]] print("(" .. _depth .. ")  token: " .. tos(token))

		-- Token is a quoted string literal?
		local b1 = type(token) == "string" and token:byte(1)

		local chunk, table_direct

		-- Expression in parentheses
		if type(token) == "table" then
			chunk = _traverse(W, token, symbols)

		-- Quote-enclosed string literal
		elseif b1 == 34 or b1 == 39 then -- " or '
			chunk = W:lit(token:sub(2, -2))

		-- Symbol lookup
		elseif symbols[token] then
			local value = symbols[token]
			local val_t = type(value)
			if val_t == "function" then
				chunk, table_direct = value(W)
				-- [[DBG1]] print("table_direct", table_direct)

			elseif val_t == "string" or val_t == "number" or value == true then
				chunk = value

			else
				W:error(interp(lang.err_bad_lookup, token, val_t))
			end

		else
			W:error(interp(lang.err_no_lookup, token))
		end

		if chunk then
			local typ_ch = type(chunk)

			-- [[DBG1]] print("|" .. tostring(chunk) .. "|")

			if typ_ch == "string" or typ_ch == "number" or (typ_ch == "table" and table_direct == true) then
				ret[#ret + 1] = chunk

			elseif typ_ch == "table" then
				for _, v in ipairs(chunk) do
					ret[#ret + 1] = v
				end

			-- true: accept the result but do not add anything to the return table
			-- Treat everything else as an error
			elseif chunk ~= true then
				W:error(interp(lang.err_bad_return, typ_ch))
			end

			-- repeat the token?
			local rep = t[i]
			if rep == "*" or rep == "+" then
				i = old_i
				n_reps = n_reps + 1

			-- zero-or-one?
			elseif rep == "?" then
				i = i + 1

			elseif t[i] == "|" then
				-- [[DBG1]] print("  break loop to skip potential alternate choices.")
				break
			end

		-- not chunk
		else
			local rep = t_reps[t[i]]
			if rep then
				i = i + 1
			end
			if rep ~= "?" and rep ~= "*" and not (rep == "+" and n_reps > 0) then
				-- Is there an alternate choice?
				local alt = _getAlt(t, i)
				if alt then
					-- [[DBG1]] print("  empty table to try alternate choices")
					for x = #ret, 1, -1 do
						ret[x] = nil
					end
					W:seek(orig_wi)
					i = alt + 1
				else
					-- Not a match: discard results and reset the Walker position.
					-- [[DBG1]] print("REP", rep, "N_REPS", n_reps)
					-- [[DBG1]] print("(" .. _depth .. ") _traverse(): End early (missing required token).")
					_depth = _depth - 1
					W:seek(orig_wi)
					return false
				end
			end
		end
	end

	-- [[DBG1]] print("(" .. _depth .. ") _traverse(): End.")
	_depth = _depth - 1
	return ret
end


function M.traverse(W, t, symbols)
	_assertType(1, W, "table")
	_assertType(2, t, "table")
	_assertType(3, symbols, "table")

	return _traverse(W, t, symbols)
end


function M.checkSymbols(symbols)
	_assertType(1, symbols, "table")

	for k, v in pairs(symbols) do
		if type(k) ~= "string" then
			error(interp(lang.check_symbol_k_bad_type, type(k)))

		elseif type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "function" and v ~= "table" and v ~= true then
			local got = v == false and "false" or type(v)
			error(interp(lang.check_symbol_v_bad_type, k, got))
		end
	end
end


local function _getWords(t, _sym)
	_sym = _sym or {}
	for i, chunk in ipairs(t) do
		if type(chunk) == "table" then
			_getWords(t, _sym)

		elseif type(chunk) == "string" and not chunk:sub(1, 1):match("['\"]") then
			_sym[chunk] = true
		end
	end
end


local function _checkWords(t, _sym, _depth)
	for i, v in ipairs(t) do
		if type(v) == "table" then
			_checkWords(v, _sym, _depth + 1)

		elseif type(v) ~= "string" then
			error(interp(lang.check_word_bad_value, _depth, i, v, type(v)))

		elseif not v:sub(1, 1):match("['\"]") then
			if not _sym[v] then
				error(interp(lang.check_word_missing_sym, _depth, i, v))
			end
		end
	end
end


function M.checkWords(symbols, t)
	_assertType(1, symbols, "table")
	_assertType(2, t, "table")

	_checkWords(t, symbols, 1)
end


return M
