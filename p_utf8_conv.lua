-- PILE Base: pUtf8Conv
-- VERSION: 2.105
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


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pAssert = require(PATH .. "p_assert")
local pInterp = require(PATH .. "p_interp")
local pUtf8 = require(PATH .. "p_utf8")


local _argType = pAssert.type


local lang = {
	err_l1_unsup_cp = "unsupported code point",
	err_u16_no_space1 = "not enough space to decode a 16-bit value",
	err_u16_no_space2 = "not enough space to decode a second 16-bit value",
	err_u16_b1_oob = "first 16-byte value is out of range",
	err_u16_b2_oob = "second 16-byte value is out of range",
	err_u8_decode = "UTF-8 decoding error: $1"
}


local stringFromCode, codeFromString, step = pUtf8.stringFromCode, pUtf8.codeFromString, pUtf8.step


local concat, char = table.concat, string.char


local function fromLatin1ToUtf8(s)
	_argType(1, s, "string")

	local t = {}
	for i = 1, #s do
		t[#t + 1] = stringFromCode(s:sub(i, i):byte())
	end

	return concat(t)
end


local function fromUtf8ToLatin1(s, unmapped)
	_argType(1, s, "string")
	-- don't assert `unmapped`

	if s == "" then return "" end

	local t, i = {}, 1
	while i do
		local c, err = codeFromString(s, i)
		if not c then
			return nil, err, i

		elseif c >= 255 then
			if type(unmapped) == "string" then
				t[#t + 1] = unmapped
			else
				return nil, lang.err_l1_unsup_cp, i
			end

		else
			t[#t + 1] = char(c)
		end
		i = step(s, i)
	end

	return concat(t)
end


local function combine16Bit(s, i, big_en)
	local b1, b2 = s:byte(i), s:byte(i + 1)

	if big_en then
		b1 = b1 * 0x100
	else
		b2 = b2 * 0x100
	end

	return b1 + b2
end


local function fromUtf16ToUtf8(s, big_en)
	_argType(1, s, "string")

	local t, i = {}, 1
	while i <= #s do
		if i == #s then
			return nil, lang.err_u16_no_space1, i
		end

		local w1 = combine16Bit(s, i, big_en)

		if w1 < 0xd800 or w1 > 0xdfff then
			t[#t + 1] = stringFromCode(w1)
			i = i + 2

		elseif w1 > 0xdbff then
			return nil, lang.err_u16_b1_oob, i

		else
			i = i + 2
			if i > #s - 1 then
				return nil, lang.err_u16_no_space2, i
			end

			local w2 = combine16Bit(s, i, big_en)

			if not (w2 >= 0xdc00 and w2 <= 0xdfff) then
				return nil, lang.err_u16_b2_oob, i
			end

			t[#t + 1] = stringFromCode(((w1 % 0x400) * 0x400) + (w2 % 0x400) + 0x10000)
			i = i + 2
		end
	end

	return concat(t)
end


local function split16Bit(v, big_en)
	if big_en then
		return math.floor(v / 0x100), v % 0x100
	else
		return v % 0x100, math.floor(v / 0x100)
	end
end


local function fromUtf8ToUtf16(s, big_en)
	_argType(1, s, "string")

	if s == "" then return "" end

	local t, i = {}, 1
	while i do
		local c, err = codeFromString(s, i)
		if not c then
			return nil, pInterp(lang.err_u8_decode, err), i
		end

		local  v1, v2
		if c < 0x10000 then
			v1, v2 = split16Bit(c, big_en)
			t[#t + 1] = char(v1, v2)
		else
			c = c - 0x10000
			local w1 = 0xd800 + math.floor(c / 0x400)
			local w2 = 0xdc00 + (c % 0x400)

			v1, v2 = split16Bit(w1, big_en)
			t[#t + 1] = char(v1, v2)

			v1, v2 = split16Bit(w2, big_en)
			t[#t + 1] = char(v1, v2)
		end

		i = step(s, i)
	end

	return concat(t)
end


return {
	lang = lang,
	fromLatin1ToUtf8 = fromLatin1ToUtf8,
	fromUtf8ToLatin1 = fromUtf8ToLatin1,
	fromUtf16ToUtf8 = fromUtf16ToUtf8,
	fromUtf8ToUtf16 = fromUtf8ToUtf16
}
