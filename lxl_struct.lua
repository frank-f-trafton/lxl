-- Lua XML Library: Table structures for representing an XML node tree in Lua.
-- VERSION: 2.075
-- https://github.com/frank-f-trafton/lxl
-- See LICENSE for licensing and copyright info.

-- (Use through 'XmlObject' tables created with lxl.lua)


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local struct = {}


local namespace = require(PATH .. "lxl_namespace")
local pAssert = require(PATH .. "p_assert")
local pInterp = require(PATH .. "p_interp")
local pTree = require(PATH .. "p_tree")
local shared = require(PATH .. "lxl_shared")


local lang = shared.lang


local _assertCharacters = shared.assertCharacters


local function _checkSelf(t)
	if type(t) ~= "table" then
		error(pInterp(lang.struct_bad_self, type(t)))
	end
end


local function _insert(t, i, v)
	i = i or #t + 1
	if i < 1 or i > #t + 1 then
		error(lang.struct_insert_oob)
	end
	table.insert(t, i, v)
end


local function _findSelfAmongSiblings(self, sibs)
	if sibs then
		for i, sib in ipairs(sibs) do
			if self == sib then
				return i, self
			end
		end
	end
end


local function _resolvePath(self, path, simple)
	return pTree.nodeResolvePath(self, path, "name", simple)
end


local function _find(self, id, name, i)
	-- Don't assert 'self'
	pAssert.type(1, id, "string")
	pAssert.types(2, name, "nil", "string")
	i = i or 1
	pAssert.integerGe(3, i, 1)

	if self.nodes then
		for ii = i, #self.nodes do
			local child = self.nodes[ii]
			if child.name == name and child.id == id then
				return child, ii
			end
		end
	end
end


local function _findNS(self, ns_uri, ns_local, i)
	-- Don't assert 'self'
	pAssert.type(1, ns_uri, "string")
	pAssert.type(2, ns_local, "string")
	i = i or 1
	pAssert.integerGe(3, i, 1)

	if not self:getXmlObject().namespace_mode then
		return
	end

	if self.nodes then
		local _decl = {}
		for ii = i, #self.nodes do
			local child = self.nodes[ii]
			if child.id == "element" then
				child:getNamespaceDeclarations(_decl)
				local ns_prefix2, ns_local2 = child.name:match("^([^:]+):([^:]+)$")
				if _decl[ns_prefix2] == ns_uri and ns_local2 == ns_local then
					return child, ii
				end
			end
		end
	end
end


local function _destroy(self)
	if self.nodes then
		for i = #self.nodes, 1, -1 do
			if self.nodes[i].destroy then
				self.nodes[i]:destroy()
			end
		end
	end
	if self.parent then
		local sibs = pTree.nodeGetSiblings(self)
		for i, sibling in ipairs(sibs) do
			if sibling == self then
				table.remove(sibs, i)
				break
			end
		end
	end
	setmetatable(self, nil)
	for k in pairs(self) do
		self[k] = nil
	end
end


local function _getName(self)
	pAssert.type("self.name", self.name, "string")

	return self.name
end


local function _setName(self, name)
	_checkSelf(self)
	pAssert.type(1, name, "string")
	assert(shared.validateXMLName(name))

	self.name = name
end


local function _getText(self)
	pAssert.type("self.text", self.text, "string")

	return self.text
end


local function _newNodeDef(id)
	local node_def = {
		id = id,

		getXmlObject = pTree.nodeGetRoot,
		getParent = pTree.nodeGetParent,
		getChild = pTree.nodeGetChild,
		getSiblings = pTree.nodeGetSiblings,
		getNextSibling = pTree.nodeGetNextSibling,
		getPreviousSibling = pTree.nodeGetPreviousSibling,
		resolvePath = _resolvePath,
		find = _find,
		findInNamespace = _findNS,

		destroy = _destroy
	}
	node_def.__index = node_def
	return node_def
end


local _mt_comment = _newNodeDef("comment")


function struct.newComment(self, text, i)
	_checkSelf(self)
	pAssert.type(1, text, "string")
	_assertCharacters(text)
	assert(shared.checkXMLCommentText(text))
	pAssert.types(2, i, "nil", "number")

	if self.id == "xml_object" then
		for i, child in ipairs(self) do
			if child.id == "element" then
				error(lang.struct_2root)
			end
		end
	end

	local comment = setmetatable({parent = self, text = text}, _mt_comment)
	_insert(self.nodes, i, comment)
	return comment
end


_mt_comment.getText = _getText


function _mt_comment:setText(text)
	pAssert.type(1, text, "string")
	_assertCharacters(text)
	assert(shared.checkXMLCommentText(text))

	self.text = text
end


local _mt_pi = _newNodeDef("pi")


function struct.newProcessingInstruction(self, name, text, i)
	_checkSelf(self)
	pAssert.type(1, name, "string")
	assert(shared.validatePITarget(name))
	pAssert.type(2, text, "string")
	_assertCharacters(text)
	assert(shared.checkPIText(text))
	pAssert.types(3, i, "nil", "number")

	local pi = setmetatable({parent = self, name = name, text = text}, _mt_pi)
	_insert(self.nodes, i, pi)
	return pi
end


_mt_pi.getText = _getText


function _mt_pi:setText(text)
	pAssert.type(1, text, "string")
	_assertCharacters(text)
	assert(shared.checkPIText(text))

	self.text = text
end


_mt_pi.getTarget = _getName



function _mt_pi:setTarget(target)
	pAssert.type(1, target, "string")
	assert(shared.validatePITarget(target))

	self.name = target
end


local _mt_cdata = _newNodeDef("cdata")


function struct.newCharacterDataInternal(self, text, cd_sect, i, check_chars)
	_checkSelf(self)
	pAssert.type(1, text, "string")
	-- skip checking XML characters when parsing from a string
	-- (where the whole document was already checked)
	if check_chars then
		_assertCharacters(text)
	end
	-- don't assert 'cd_sect'
	pAssert.types(3, i, "nil", "number")

	local cdata = setmetatable({
		parent = self,
		text = text,
		cd_sect = not not cd_sect,
	}, _mt_cdata)
	_insert(self.nodes, i, cdata)
	return cdata
end


function struct.newCharacterData(self, text, cd_sect, i)
	return struct.newCharacterDataInternal(self, text, cd_sect, i, true)
end


function _mt_cdata:setText(text)
	pAssert.type(1, text, "string")
	_assertCharacters(text)

	self.text = text
end


_mt_cdata.getText = _getText


function _mt_cdata:setCdSect(enabled)
	self.cd_sect = not not enabled
end


function _mt_cdata:getCdSect()
	return self.cd_sect
end


local _mt_doctype = _newNodeDef("doctype")


function struct.newDocType(self, name, i)
	_checkSelf(self)
	pAssert.type(1, name, "string")
	assert(shared.validateXMLName(name))
	pAssert.types(2, i, "nil", "number")

	if self.id ~= "xml_object" then
		error(lang.struct_doctype_wrong_parent)
	end

	local doctype = setmetatable({
		parent = self,
		nodes = {},
		name = name,
		external_id = nil,
	}, _mt_doctype)
	_insert(self.nodes, i, doctype)

	return doctype
end


local _mt_unexp_ent = _newNodeDef("unexp")


function struct.newUnexpandedReference(self, name, i)
	_checkSelf(self)
	pAssert.type(1, name, "string")
	assert(shared.validateXMLName(name))
	pAssert.types(2, i, "nil", "number")

	local unexp_ent = setmetatable({parent = self, name = name}, _mt_unexp_ent)
	_insert(self.nodes, i, unexp_ent)
	return unexp_ent
end


_mt_unexp_ent.getName = _getName
_mt_unexp_ent.setName = _setName


local _mt_element = _newNodeDef("element")


function struct.newElement(self, name, i)
	return struct.newElementInternal(self, name, i)
end


-- NOTE: '_attribs' is for the parser, and should not be exposed to the library user through XmlObject.
function struct.newElementInternal(self, name, i, _attribs)
	_checkSelf(self)
	pAssert.type(1, name, "string")
	assert(shared.validateXMLName(name))
	pAssert.types(2, i, "nil", "number")
	pAssert.types(3, _attribs, "nil", "table")

	-- Use `_attribs` if you have already filled out an existing table of attributes,
	-- but do not attach this table to multiple elements.

	local element = setmetatable({
		parent = self,
		nodes = {},
		name = name,
		attr = _attribs or {},
	}, _mt_element)
	_insert(self.nodes, i, element)
	return element
end


_mt_element.getName = _getName
_mt_element.setName = _setName


function _mt_element:getAttribute(key)
	pAssert.type(1, key, "string")

	return self.attr[key]
end


function _mt_element:setAttribute(key, value)
	pAssert.type(1, key, "string")
	assert(shared.validateXMLName(key))
	pAssert.types(2, value, "nil", "string")
	if value then
		_assertCharacters(value)
	end

	self.attr[key] = value
end


_mt_element.newCharacterData = struct.newCharacterData
_mt_element.newComment = struct.newComment
_mt_element.newProcessingInstruction = struct.newProcessingInstruction
_mt_element.newElement = struct.newElement


function _mt_element:getNamespaceDeclarations(_decl)
	pAssert.types(1, _decl, "nil", "table")

	_decl = _decl or {}
	for k, v in pairs(_decl) do
		_decl[k] = nil
	end
	if not self:getXmlObject().namespace_mode then
		return _decl
	end
	local node = self
	repeat
		for k, v in pairs(node.attr) do
			if k == "xmlns" and not _decl[true] then
				_decl[true] = v
			else
				local ns_local = k:match("^xmlns:([^:]+)$")
				if ns_local and not _decl[ns_local] then
					_decl[ns_local] = v
				end
			end
		end
		node = node.parent
	until not node.parent
	return _decl
end


function _mt_element:getNamespaceBinding(ns_uri)
	pAssert.type(1, ns_uri, "string")

	if not self:getXmlObject().namespace_mode then
		return
	end
	-- Predefined namespaces
	if ns_uri == namespace.predefined["xml"] then
		return "xml"

	elseif ns_uri == namespace.predefined["xmlns"] then
		return "xmlns"
	end

	local decl = self:getNamespaceDeclarations()
	for k, v in pairs(decl) do
		if k ~= true and v == ns_uri then
			return k
		end
	end
end


function _mt_element:getNamespace()
	local ns_mode = self:getXmlObject().namespace_mode
	if not ns_mode then
		return
	end
	local decl = self:getNamespaceDeclarations()
	local ns_prefix, ns_local = self.name:match("^([^:]+):([^:]+)$")
	-- default _namespace
	if not ns_prefix then
		return decl[true] ~= "" and decl[true] or nil
	else
		if ns_mode ~= "1.1" and decl[ns_prefix] == "" then
			error(lang.struct_ns1_undeclare_prefix)
		end
		return decl[ns_prefix] ~= "" and decl[ns_prefix] or nil
	end
end


function _mt_element:getNamespaceAttribute(ns_uri, ns_local)
	pAssert.type(1, ns_uri, "string")
	pAssert.type(2, ns_local, "string")

	if not self:getXmlObject().namespace_mode then
		return
	end
	local ns_prefix = self:getNamespaceBinding(ns_uri)
	if ns_prefix then
		local key = ns_prefix .. ":" .. ns_local
		return self.attr[key], ns_prefix
	end
end


function _mt_element:setAttribute(key, value)
	pAssert.type(1, key, "string")
	assert(shared.validateXMLName(key))
	pAssert.types(2, value, "nil", "string")
	if value then
		_assertCharacters(value)
	end

	self.attr[key] = value
end


function _mt_element:getStableAttributesOrder()
	return shared.orderedKeys(self.attr)
end


-- xml:space, xml:lang
function _mt_element:getXmlSpecialAttribute(local_name)
	local obj = self
	repeat
		local a_value = obj:getAttribute("xml:" .. local_name)
		if a_value then
			return a_value, obj
		end
		obj = obj.parent
	until not obj.parent
end


local _mt_xml_obj = _newNodeDef("xml_object")


function struct.newXmlObject()
	return setmetatable({
		nodes = {},

		-- XML Declaration state
		version = nil,
		encoding = nil,
		standalone = nil,

		-- Namespace mode
		-- XmlParser sets this when loading from string
		-- nil, "1.0", "1.1"
		namespace_mode = nil,

		doctype_str = nil,

		-- general entities
		g_entities = {},

		-- parameter entities
		p_entities = {},

		-- attribute defaults from ATTLIST declarations
		attr_defaults = {},

		-- We don't collect notation declarations
	}, _mt_xml_obj)
end


function _mt_xml_obj:setXmlVersion(v)
	pAssert.types(1, v, "nil", "string")
	if v and not v:match("1%.[0-9]+") then
		error(lang.struct_bad_xml_ver)
	end

	self.version = v
end


function _mt_xml_obj:getXmlVersion()
	return self.version
end


function _mt_xml_obj:setXmlEncoding(e)
	pAssert.types(1, e, "nil", "string")
	if e ~= nil and e ~= "UTF-8" and e ~= "UTF-16" then
		error(lang.struct_bad_xml_enc)
	end

	self.encoding = e
end


function _mt_xml_obj:getXmlEncoding()
	return self.encoding
end


function _mt_xml_obj:setXmlStandalone(s)
	pAssert.types(1, s, "nil", "string")
	if s ~= nil and s ~= "yes" and s ~= "no" then
		error(lang.struct_bad_xml_sta)
	end
	self.standalone = s
end


function _mt_xml_obj:getXmlStandalone()
	return self.standalone
end


function _mt_xml_obj:setNamespaceMode(mode)
	if mode ~= nil and mode ~= "1.0" and mode ~= "1.1" then
		error(lang.struct_bad_ns_mode)
	end
	self.namespace_mode = mode
end


function _mt_xml_obj:getNamespaceMode()
	return self.namespace_mode
end


_mt_xml_obj.newComment = struct.newComment
_mt_xml_obj.newProcessingInstruction = struct.newProcessingInstruction
_mt_xml_obj.newElement = struct.newElement


local function _pruneNodes(self, ...)
	local nodes = self.nodes
	for i = #nodes, 1, -1 do
		local child = nodes[i]
		if child.nodes then
			_pruneNodes(child, ...)
		else
			for j = 1, select("#", ...) do
				if child.id == select(j, ...) then
					table.remove(nodes, i)
					break
				end
			end
		end
	end
end


function _mt_xml_obj:pruneNodes(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		pAssert.type(i, v, "string")
	end

	_pruneNodes(self, ...)
end


local function _mergeCharacterData(self, _temp)
	-- collect adjacent CharacterData nodes, then concatenate in a second pass
	local nodes = self.nodes
	local i = 1
	while i <= #nodes do
		local node1, node2 = nodes[i], nodes[i + 1]
		if node1.nodes then
			_mergeCharacterData(node1, _temp)
			i = i + 1

		elseif node1.id == "cdata" and node2 and node2.id == "cdata" then
			_temp[node1] = _temp[node1] or {node1.text}
			table.insert(_temp[node1], node2.text)
			-- remove node2
			table.remove(nodes, i + 1)
		else
			i = i + 1
		end
	end
	for node, array in pairs(_temp) do
		node.text = table.concat(array)
		node.cd_sect = false
		_temp[node] = nil
	end
end


function _mt_xml_obj:mergeCharacterData()
	_mergeCharacterData(self, {})
end


local function _pruneSpace(self, xml_space)
	local nodes = self.nodes
	for i = #nodes, 1, -1 do
		local child = nodes[i]
		if (not xml_space or self:getXmlSpecialAttribute("space") ~= "preserve")
		and child.id == "cdata" and not child.text:find("[^\9\10\13\32]")
		then
			table.remove(nodes, i)

		elseif child.id == "element" then
			_pruneSpace(child, xml_space)
		end
	end
end


function _mt_xml_obj:pruneSpace(xml_space)
	_pruneSpace(self:getRootElement(), xml_space)
end


function _mt_xml_obj:getRootElement()
	for i, child in ipairs(self.nodes) do
		if child.id == "element" then
			return child
		end
	end
	error(lang.struct_missing_xml_obj)
end


function _mt_xml_obj:getDoctype()
	for i, child in ipairs(self.nodes) do
		if child.id == "doctype" then
			return child
		end
	end
end


local function _checkNamespaceState(self, ns_mode)
	if self.id == "pi" then
		namespace.checkNoColon(self.name)

	elseif self.id == "element" then
		namespace.checkElement(self, ns_mode)
		for i, node in ipairs(self.nodes) do
			_checkNamespaceState(node, ns_mode)
		end
	end
end


function _mt_xml_obj:checkNamespaceState()
	if not self.namespace_mode then
		return
	end
	for k, entity in pairs(self.g_entities) do
		namespace.checkNoColon(k)
	end
	-- checkNoColon: notation declarations are not attached to the XmlObject tree.
	for i, node in ipairs(self.nodes) do
		_checkNamespaceState(node, self.namespace_mode)
	end
end


return struct
