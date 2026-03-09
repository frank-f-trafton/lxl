# v2.070 -- 09 Mar 2026

* Changed version scheme from `n.n.n` to `n.nnn…`.
* Upgraded PILE Base from version 1.1.1 to 2.101.
* Updated license and copyright text to reflect changes to PILE Base.
* Added `name` parameter to `lxl.toTable()` and `xmlParser:toTable()`, so that applications may include a filename (or some other indication of provenance) in error messages.
* Added `lxl.fragmentToString()` and `xmlParser:fragmentToString()`.
* To support method chaining, added `return self` to these xmlParser methods:
  * `xmlParser:setCheckCharacters()`
  * `xmlParser:setNamespaceMode()`
  * `xmlParser:setCollectComments()`
  * `xmlParser:setCollectProcessingInstructions()`
  * `xmlParser:setNormalizeLineEndings()`
  * `xmlParser:setCheckEncodingMismatch()`
  * `xmlParser:setMaxEntityBytes()`
  * `xmlParser:setRejectDoctype()`
  * `xmlParser:setRejectInternalSubset()`
  * `xmlParser:setCopyDocType()`
  * `xmlParser:setRejectUnexpandedEntities()`
  * `xmlParser:setWarnDuplicateEntityDeclarations()`
  * `xmlParser:setWriteXMLDeclaration()`
  * `xmlParser:setWriteDocType()`
  * `xmlParser:setWritePretty()`
  * `xmlParser:setWriteIndent()`
  * `xmlParser:setWriteBigEndian()`
* Replaced some node methods with functions from PILE Tree. The following were renamed: (\* == the behaviour has changed!)
  * `Node:ascend() -> Node:getParent()`
  * `Node:descend() -> Node:getChild(1)` \*
  * `Node:next()` -> `Node:getNextSibling()`
  * `Node:prev()` -> `Node:getPreviousSibling()`
  * `Node:top() -> Node:getXMLObject()`
  * `Node:path()` -> `Node:resolvePath()` \*
* Renamed `Node:getRoot()` to `Node:getRootElement()`.
* To support the integration with PILE Tree, all `Node.children` tables have been renamed to `Node.nodes`.


# v2.0.6 -- 03 Mar 2026

* Started an AsciiDoc version of the documentation in `docs`. It will replace the README.md as soon as I figure out how to make it accessible on GH Pages.
* Updated the copyright year.


# v2.0.5 -- 02 Jan 2025

* [GitHub Issue #1](https://github.com/rabbitboots/lxl/issues/1): changed `#FIXED` attribute behavior to match [LuaExpat](https://lunarmodules.github.io/luaexpat/).
  * Previously, `#FIXED` attributes would overwrite existing attribute values in the document. Now, they are ignored.


# v2.0.4 -- 07 Oct 2024

* Renamed files:
  * Library files beginning with `xml` now start with `lxl`
  * Renamed test files to be more descriptive.
* Flattened the `test` folder.
* Moved library files out of `xml_lib` and into the main directory.
* Integrated snippets from PILE (type checker, etc.).
* Replaced `utf8_tools.lua` with `pile_utf8.lua` and `utf8_conv.lua` with `pile_utf8_conv.lua`.
* Gathered license text for test libraries into the file `test_LICENSE`.


# v2.0.3 -- 01 Oct 2024

* Updated license text to include the copyright for code from kikito/utf8_validator.lua (in xml_shared.lua).


# v2.0.2 -- 06 Sept 2024

* Added `Parser:setCheckCharacters()` and `Parser:getCheckCharacters()`.
* Modified `shared.checkXMLCharacters()` to include logic based on [kikito's utf8_validator.lua](https://github.com/kikito/utf8_validator.lua). (See also utf8Tools, where the code is imported as `utf8Tools.checkAlt()`.) This pattern-based code is faster when run under PUC-Lua.
* Updated libraries: errTest (2.1.1 -> 2.1.2), utf8Tools (1.3.0 -> 1.4.0)
* Simplified the layout of code point lookup tables in xmlShared.

# v2.0.1 -- 08 Jul 2024

* Added xml.load()


# v2.0.0 -- 05 Jul 2024

This is a major rewrite of [xmlToTable](https://github.com/rabbitboots/xml_to_table). Unfortunately, there are so many changes that it's not possible to write a straightforward upgrade guide. The main improvements are:

* UTF-16 support (internal conversion to UTF-8)
* Parsing of DOCTYPE tags and the DTD internal subset (in a non-validating manner)
* More conformant handling of whitespace
* Serialization has been promoted from "for debugging purposes" to an official feature
* Attribute order is discarded; duplicate attributes are not allowed at all. It was a mistake to order attributes in the first place.
* XML Declarations are now handled
* Support for `xml:space="preserve"` when pruning whitespace
* Some support for XML Namespaces 1.0 and 1.1
