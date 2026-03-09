-- Lua XML Library
-- VERSION: 2.070
-- https://github.com/frank-f-trafton/lxl
-- See LICENSE for licensing and copyright info.

-- Test: main file


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


require(PATH .. "test.strict")


local errTest = require(PATH .. "test.err_test")
local inspect = require(PATH .. "test.inspect")
local pretty = require(PATH .. "test_pretty")
local pUTF8 = require(PATH .. "pile_utf8")
local pUTF8Conv = require(PATH .. "pile_utf8_conv")
local shared = require(PATH .. "lxl_shared")
local lxl = require(PATH .. "lxl")


local hex = string.char


local cli_verbosity
for i = 0, #arg do
	if arg[i] == "--verbosity" then
		cli_verbosity = tonumber(arg[i + 1])
		if not cli_verbosity then
			error("invalid verbosity value")
		end
	end
end


local self = errTest.new("xmlParser", cli_verbosity)


self:registerFunction("lxl.toTable()", lxl.toTable)


-- lxl.newParser(): nothing to test


-- [===[
self:registerJob("xmlParser:setNamespaceMode(), getNamespaceMode()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		self:expectLuaError("arg #1 bad input", p.setNamespaceMode, p, "foobar")
		p:setNamespaceMode("1.1")
		self:isEqual(p:getNamespaceMode(), "1.1")
	end
	--]====]


	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setNamespaceMode("1.1"):setNamespaceMode("1.0")
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setCollectComments(), getCollectComments()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setCollectComments()
		self:isEvalFalse(p:getCollectComments())
		local o = p:toTable([=[<!--foo--><r/>]=])
		self:isEqual(o.nodes[1].id, "element")
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setCollectComments(true):setCollectComments(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setCollectProcessingInstructions(), getCollectProcessingInstructions()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setCollectProcessingInstructions()
		self:isEvalFalse(p:getCollectProcessingInstructions())
		local o = p:toTable([=[<?pi foo?><r/>]=])
		self:isEqual(o.nodes[1].id, "element")
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setCollectProcessingInstructions(true):setCollectProcessingInstructions(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setNormalizeLineEndings(), getNormalizeLineEndings()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setNormalizeLineEndings()
		self:isEvalFalse(p:getNormalizeLineEndings())
		local o = p:toTable("<r>.\r\n.</r>")
		self:isEqual(o.nodes[1].nodes[1].id, "cdata")
		self:isEqual(o.nodes[1].nodes[1].text, ".\r\n.")
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setNormalizeLineEndings(true):setNormalizeLineEndings(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setCheckEncodingMismatch(), getCheckEncodingMismatch()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setCheckEncodingMismatch()
		self:isEvalFalse(p:getCheckEncodingMismatch())
		local o = p:toTable([=[<?xml version="1.0" encoding="UTF-3000"?><r/>]=])
		self:isEqual(o.encoding, "UTF-3000")
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setCheckEncodingMismatch(true):setCheckEncodingMismatch(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setMaxEntityBytes(), getMaxEntityBytes()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setMaxEntityBytes(0)
		self:isEqual(p:getMaxEntityBytes(), 0)
		self:expectLuaError("trip the max entity bytes setting", p.toTable, p, [=[
<!DOCTYPE r [
<!ENTITY foo "barbarbar">
]>
<r>&foo;</r>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setMaxEntityBytes(1):setMaxEntityBytes(2)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setRejectDoctype(), getRejectDoctype()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setRejectDoctype(true)
		self:isEqual(p:getRejectDoctype(), true)
		self:expectLuaError("trip the 'reject doctype' setting", p.toTable, p, [=[<!DOCTYPE r><r/>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setRejectDoctype(true):setRejectDoctype(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setRejectInternalSubset(), getRejectInternalSubset()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setRejectInternalSubset(true)
		self:isEqual(p:getRejectInternalSubset(), true)
		self:expectLuaError("trip the 'reject internal subset' setting", p.toTable, p, [=[<!DOCTYPE r [<!ENTITY f "b">]><r/>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setRejectInternalSubset(true):setRejectInternalSubset(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setCopyDocType(), getCopyDocType()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setCopyDocType(true)
		self:isEqual(p:getCopyDocType(), true)
		local o = p:toTable([=[<!DOCTYPE r [<!ENTITY foo "bar">]><r/>]=])

		self:isEqual(o.doctype_str, [=[<!DOCTYPE r [<!ENTITY foo "bar">]>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setCopyDocType(true):setCopyDocType(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setRejectUnexpandedEntities(), getRejectUnexpandedEntities()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setRejectUnexpandedEntities(true)
		self:isEqual(p:getRejectUnexpandedEntities(), true)

		self:expectLuaError("test 'reject unexpanded references' setting", p.toTable, p, [=[
<!DOCTYPE r [
<!ENTITY % pe "zoop">
%pe;
]>
<r>&undeclared;</r>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setRejectUnexpandedEntities(true):setRejectUnexpandedEntities(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setWarnDuplicateEntityDeclarations(), getWarnDuplicateEntityDeclarations()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWarnDuplicateEntityDeclarations(true)
		self:isEqual(p:getWarnDuplicateEntityDeclarations(), true)

		local o = p:toTable([=[
<!DOCTYPE r [
<!ENTITY fo "a">
<!ENTITY fo "b">
<!ENTITY % pe "c">
<!ENTITY % pe "d">
%pe;
]>
<r/>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWarnDuplicateEntityDeclarations(true):setWarnDuplicateEntityDeclarations(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]



-- [===[
self:registerJob("xmlParser:setWriteXMLDeclaration(), getWriteXMLDeclaration()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWriteXMLDeclaration(false)
		self:isEqual(p:getWriteXMLDeclaration(), false)

		local o = lxl.newXMLObject()
		o:newElement("root")
		local s = p:toString(o)
		self:isEqual(s, [=[<root/>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWriteXMLDeclaration(true):setWriteXMLDeclaration(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setWriteDocType(), getWriteDocType()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWriteDocType(true)
		self:isEqual(p:getWriteDocType(), true)
		local o = lxl.newXMLObject()
		o.doctype_str = [=[
<!DOCTYPE root [
<!ENTITY foo "bar">
]>]=]

		o:newElement("root")
		local s = p:toString(o)
		self:isEqual(s, [=[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
<!ENTITY foo "bar">
]>
<root/>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWriteDocType(true):setWriteDocType(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setWritePretty(), getWritePretty()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWritePretty(false)
		self:isEvalFalse(p:getWritePretty())
		local o = lxl.newXMLObject()
		local e1 = o:newElement("root")
		local e2 = e1:newElement("a")
		local e3 = e2:newElement("b")
		local e4 = e3:newElement("c")
		local e5 = e4:newElement("d")
		local s = p:toString(o)
		self:isEqual(s, [=[<?xml version="1.0" encoding="UTF-8"?><root><a><b><c><d/></c></b></a></root>]=])
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWritePretty(true):setWritePretty(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setWriteBigEndian(), getWriteBigEndian()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWriteXMLDeclaration(false)
		p:setWriteBigEndian(true)
		self:isEqual(p:getWriteBigEndian(), true)
		local o = lxl.newXMLObject()
		o:setXMLEncoding("UTF-16")
		local e1 = o:newElement("root")
		local s = p:toString(o)
		local comparison, c_i, c_err = shared.bom_utf16_be .. pUTF8Conv.utf8_utf16([=[<root/>]=], true)
		if not comparison then error(c_err) end
		self:isEqual(s, comparison)
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWriteBigEndian(true):setWriteBigEndian(false)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:setWriteIndent(), getWriteIndent()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWriteXMLDeclaration(false)
		p:setWriteIndent("\t", 2)
		local ch, qty = p:getWriteIndent()
		self:isEqual(ch, "\t")
		self:isEqual(qty, 2)
		local o = lxl.newXMLObject()
		local e1 = o:newElement("root")
		local e2 = e1:newElement("a")
		local s = p:toString(o)
		self:isEqual(s, "<root>\n\t\t<a/>\n</root>")
	end
	--]====]

	-- [====[
	do
		self:print(4, "Test method chaining")
		local p = lxl.newParser()
		local rv = p:setWriteIndent("\t", 1):setWriteIndent("\t", 4)
		self:isEqual(p, rv)
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:toTable()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		local o = p:toTable([=[<root>foobar</root>]=])
		self:isEqual(o.nodes[1].id, "element")
		self:isEqual(o.nodes[1].name, "root")
		self:isEqual(o.nodes[1].nodes[1].id, "cdata")
		self:isEqual(o.nodes[1].nodes[1].text, "foobar")
	end


	-- [====[
	do
		self:print(3, "Test including a name in error output")
		local p = lxl.newParser()
		local ok, err = pcall(p.toTable, p, [=[<root></bad-tag>]=], "my_cool_document.xml")
		self:isEvalFalse(ok)
		local i = err:find("my_cool_document.xml")
		self:print(4, "The error: " .. err)
		self:isEvalTrue(i)
	end
	--]====]


	-- [====[
	do
		local p = lxl.newParser()
		self:expectLuaError("arg #1 bad type", p.toTable, p, {})
		self:expectLuaError("arg #1 bad input", p.toTable, p, "zyp")
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:toString()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		p:setWriteXMLDeclaration(false)
		local o = lxl.newXMLObject()
		local e = o:newElement("root")
		local e2 = e:newCharacterData("foobar")
		local s = p:toString(o)
		self:isEqual(s, "<root>foobar</root>")
	end
	--]====]


	-- [====[
	do
		local p = lxl.newParser()
		self:expectLuaError("arg #1 bad type", p.toString, p, false)
		self:expectLuaError("arg #1 bad input", p.toString, p, {})
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xmlParser:fragmentToString()", function(self)
	-- [====[
	do
		local p = lxl.newParser()
		local o = lxl.newXMLObject()
		local e = o:newElement("root")
		local e2 = e:newElement("trunk")
		local e3 = e2:newCharacterData("bark")
		local s = p:fragmentToString(e)
		self:isEqual(s, "<trunk>bark</trunk>")
	end
	--]====]


	-- [====[
	do
		local p = lxl.newParser()
		self:expectLuaError("arg #1 bad type", p.fragmentToString, p, false)
		self:expectLuaError("arg #1 bad input", p.fragmentToString, p, {})
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("xml.toTable()", function(self)
	-- [====[
	do
		local o = lxl.toTable([=[<root>foobar</root>]=])
		self:isEqual(o.nodes[1].id, "element")
		self:isEqual(o.nodes[1].name, "root")
		self:isEqual(o.nodes[1].nodes[1].id, "cdata")
		self:isEqual(o.nodes[1].nodes[1].text, "foobar")
	end
	--]====]

	-- [====[
	do
		self:print(3, "Test including a name in error output")
		local ok, err = pcall(lxl.toTable, [=[<root></bad-tag>]=], "my_cool_document.xml")
		self:isEvalFalse(ok)
		local i = err:find("my_cool_document.xml")
		self:print(4, "The error: " .. err)
		self:isEvalTrue(i)
	end
	--]====]

	-- [====[
	do
		self:expectLuaError("arg #1 bad type", lxl.toTable, {})
		self:expectLuaError("arg #1 bad input", lxl.toTable, "zyp")
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("lxl.toString()", function(self)
	-- [====[
	local o = lxl.newXMLObject()
	local e = o:newElement("root")
	local e2 = e:newCharacterData("foobar")
	local s = lxl.toString(o)
	self:isEqual(s, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>foobar</root>")

	self:expectLuaError("arg #1 bad type", lxl.toString, false)
	self:expectLuaError("arg #1 bad input", lxl.toString, {})
	--]====]
end
)
--]===]


-- [===[
self:registerJob("lxl.fragmentToString()", function(self)
	-- [====[
	do
		local o = lxl.newXMLObject()
		local e = o:newElement("root")
		local e2 = e:newElement("trunk")
		local e3 = e2:newCharacterData("bark")
		local s = lxl.fragmentToString(e)
		self:isEqual(s, "<trunk>bark</trunk>")
	end
	--]====]


	-- [====[
	do
		self:expectLuaError("arg #1 bad type", lxl.fragmentToString, false)
		self:expectLuaError("arg #1 bad input", lxl.fragmentToString, {})
	end
	--]====]
end
)
--]===]


-- lxl.newXMLObject() -- nothing to test.


-- [===[
self:registerJob("lxl.load()", function(self)
	-- [====[
	self:expectLuaError("arg #1 bad type", lxl.load, {})
	self:expectLuaError("arg #1 non-existent file", lxl.load, "not-a-real-file.ex-em-el")

	local o = lxl.load("test_lxl.xml")
	o:pruneSpace()
	self:isEqual(o.nodes[1].id, "element")
	self:isEqual(o.nodes[1].name, "house")
	self:isEqual(o.nodes[1].nodes[1].id, "element")
	self:isEqual(o.nodes[1].nodes[1].name, "room")
	self:isEqual(o.nodes[1].nodes[1].nodes[1].id, "cdata")
	self:isEqual(o.nodes[1].nodes[1].nodes[1].text, "Entry way")

	self:isEqual(o.nodes[1].nodes[2].id, "element")
	self:isEqual(o.nodes[1].nodes[2].name, "room")
	self:isEqual(o.nodes[1].nodes[2].nodes[1].id, "cdata")
	self:isEqual(o.nodes[1].nodes[2].nodes[1].text, "Kitchen")

	self:isEqual(o.nodes[1].nodes[3].id, "element")
	self:isEqual(o.nodes[1].nodes[3].name, "room")
	self:isEqual(o.nodes[1].nodes[3].nodes[1].id, "cdata")
	self:isEqual(o.nodes[1].nodes[3].nodes[1].text, "Living room")

	self:isEqual(o.nodes[1].nodes[4].id, "element")
	self:isEqual(o.nodes[1].nodes[4].name, "room")
	self:isEqual(o.nodes[1].nodes[4].nodes[1].id, "cdata")
	self:isEqual(o.nodes[1].nodes[4].nodes[1].text, "Bathroom")

	self:isEqual(o.nodes[1].nodes[5].id, "element")
	self:isEqual(o.nodes[1].nodes[5].name, "room")
	self:isEqual(o.nodes[1].nodes[5].nodes[1].id, "cdata")
	self:isEqual(o.nodes[1].nodes[5].nodes[1].text, "Bedroom")
	--]====]
end
)
--]===]


self:runJobs()
