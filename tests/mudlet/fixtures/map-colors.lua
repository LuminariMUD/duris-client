local T = DurisTest
ArjUI.initialDataRequested = true

-- Duris AnsiString::ansi() writes &=<background><foreground> and
-- &+<foreground> clears the previous background (src/net/ansi.c).
local map = "&=lB~&+g.&=bY^&+g.&n plain\n"
    .. "&=bY^&+g.&-r &+W@&n reset\n"
    .. "&=bY^\nnext line\n"
    .. "&=bY^\\nlegacy line\n"
    .. "&+lblack&n &=lWwhite&n\n"
    .. "&=bB &+g. water\n"
    .. "&=wl^&+g. &+W+&+g. &+L+&+g. &+W@&n markers"

local function colorAt(name, text, offset, foreground)
    for line = 0, getLastLineNumber(name) do
        local value = (getLines(name, line, line + 1) or {})[1] or ""
        local column = value:find(text, 1, true)
        if column then
            moveCursor(name, 0, line)
            selectSection(name, column - 1 + (offset or 0), 1)
            local r, g, b
            if foreground then r, g, b = getFgColor(name)
            else r, g, b = getBgColor(name) end
            deselect(name)
            return string.format("%d,%d,%d", r, g, b)
        end
    end
    error("Missing text in " .. name .. ": " .. text)
end

local function wild(room, text)
    T.emit("Room.Info", {num=0, zone=600, name=room, area="Open plains", exits={north=true}})
    T.emit("Room.Map", {map=text})
end

local function ansiRGB(index)
    return table.concat(color_table[string.format("ansi_%03d", index)], ",")
end

-- ANSI order differs from Duris's internal blue/green/red color-bit order.
local codes = "lrgybmcwLRGYBMCW"
local function checkPalette(first)
    local rows = {}
    for index = first, first + 7 do
        local code = codes:sub(index + 1, index + 1)
        local label = string.format(" palette%02d", index)
        rows[#rows + 1] = "&+" .. code .. "F&-" .. code .. "B&=" .. code .. code .. "C&n" .. label
        -- Independent reference: let Mudlet's actual ANSI decoder resolve
        -- the same profile color in foreground, background and both together.
        feedTriggers(string.format("\27[0;38;5;%dmF\27[0;48;5;%dmB\27[38;5;%dmC\27[0m%s\n",
            index, index, index, label))
    end
    wild("ANSI palette", table.concat(rows, "\n"))
    for index = first, first + 7 do
        local row = string.format("FBC palette%02d", index)
        for _, cell in ipairs({{0, true}, {1, false}, {2, true}, {2, false}}) do
            T.check(colorAt("ArjMapper_Wild", row, cell[1], cell[2]) == colorAt("ArjUI_Console", row, cell[1], cell[2]),
                string.format("ANSI %02d %s at cell %d matches game output", index, cell[2] and "foreground" or "background", cell[1]))
        end
    end
end

-- Real default zone glyph, a customized white-plus zone glyph, an ordinary
-- grey road/city plus, and the player. Symbols must not decide their colors.
local markers = "&+g....&=wl^&+g....\n&+g..&+W+&+g......\n&+g...&+L+&+g.....\n&+g....&+W@&+g...."
local function checkMarkers(stage)
    local name = "ArjMapper_Wild"
    T.check(colorAt(name, "....^....", 4, true) == ansiRGB(0), stage .. ": default zone keeps black foreground")
    T.check(colorAt(name, "....^....", 4) == ansiRGB(7), stage .. ": default zone keeps white background")
    T.check(colorAt(name, "..+......", 2, true) == ansiRGB(15), stage .. ": custom white-plus zone keeps bright white")
    T.check(colorAt(name, "...+.....", 3, true) == ansiRGB(8), stage .. ": road/city plus stays grey")
    T.check(colorAt(name, "....@....", 4, true) == ansiRGB(15), stage .. ": player stays bright white")
    T.check(colorAt(name, "....^....", 5, true) == ansiRGB(2) and colorAt(name, "....^....", 5) == "12,11,9",
        stage .. ": neighboring plains retain color and clear marker background")
end

T.steps({
    {name="colored-map", run=function()
        -- Fit all diagnostic rows in the narrow map panel at 720p, too.
        ArjMapper.ui.wildConsole:setFontSize(9)
        wild("Initial wilderness", map)
        feedTriggers("\27[0;34m~\27[0;32m.\27[0;1;33;44m^\27[0;32m.\27[0m console map\n")
        feedTriggers("After initial map: plain output.\n")
    end},
    {name="color-transitions", run=function()
        local name = "ArjMapper_Wild"
        local bg = "12,11,9"
        T.check(colorAt(name, "~.^.", 0, true) == ansiRGB(12), "black-background ocean has profile blue foreground")
        T.check(colorAt(name, "~.^.") == ansiRGB(0), "black-background ocean has profile black background")
        T.check(colorAt(name, "~.^.", 2, true) == ansiRGB(11), "combined code keeps profile yellow mountain foreground")
        T.check(colorAt(name, "~.^.", 2) == ansiRGB(4), "combined code keeps profile blue mountain background")
        T.check(colorAt(name, "~.^.", 3) == bg, "foreground-only terrain clears preceding background")
        T.check(colorAt(name, "^. @", 2) == ansiRGB(1), "background-only code colors a space")
        T.check(colorAt(name, "^. @", 2, true) == colorAt(name, "reset", 0, true), "background-only code clears previous foreground")
        T.check(colorAt(name, "^. @", 3) == bg, "foreground after background-only code resets background")
        T.check(colorAt(name, "plain") == bg and colorAt(name, "reset") == bg, "reset clears map background")
        T.check(colorAt(name, "next line") == bg and colorAt(name, "legacy line") == bg, "real and legacy newlines clear map background")
        T.check(colorAt(name, "black", 0, true) == ansiRGB(0), "lowercase black is distinct from bright black")
        T.check(colorAt(name, " . water") == ansiRGB(4) and colorAt(name, " . water", 1) == bg, "real water-to-plains glyph transition clears blue background")
        T.check(colorAt("ArjUI_Console", "After initial map:") == "0,0,0", "plain console output after initial map stays black")
    end},
    {name="movement", run=function()
        expandAlias("north")
        wild("After moving north", "&=bY^&+g.&+W@ moved")
        ArjMapper.ui.wildConsole:echo(" tail")
        feedTriggers("After movement: plain output.\n")
        T.check(colorAt("ArjMapper_Wild", "^.@", 1) == "12,11,9", "movement redraw clears terrain background")
        T.check(not T.lines("ArjMapper_Wild"):find("plain", 1, true), "movement replaces previous map")
        T.check(colorAt("ArjMapper_Wild", "tail") == "12,11,9", "unterminated colored map leaves following text at default background")
        T.check(colorAt("ArjUI_Console", "After movement:") == "0,0,0", "console after movement stays black")
    end},
    {name="look", run=function()
        expandAlias("look")
        wild("After look", "@. looked\n")
        feedTriggers("After look: plain output.\n")
        T.check(colorAt("ArjMapper_Wild", "@.") == "12,11,9", "look redraw does not inherit old map colors")
        T.check(colorAt("ArjUI_Console", "After look:") == "0,0,0", "console after look stays black")
    end},
    {name="standard-palette", run=function() checkPalette(0) end},
    {name="bright-palette", run=function() checkPalette(8) end},
    {name="literal-glyphs", run=function()
        wild("Literal map text", "<red> &q &+? <blue>\n&+W^>v<")
        T.check(T.lines("ArjMapper_Wild"):find("<red> &q &+? <blue>", 1, true), "uncolored angle brackets and unknown codes remain literal")
        T.check(T.lines("ArjMapper_Wild"):find("^>v<", 1, true), "colored ship-arrow variants remain literal")
    end},
    {name="zone-markers", run=function()
        wild("Zone markers", markers)
        checkMarkers("initial")
    end},
    {name="marker-movement", run=function()
        expandAlias("north")
        wild("Zone markers after movement", markers)
        checkMarkers("movement")
    end},
    {name="marker-refresh", run=function()
        expandAlias("look")
        wild("Zone markers after look", markers)
        checkMarkers("refresh")
    end},
    {name="marker-zoom", run=function()
        local zoom = ArjMapper.config.wildZoom
        ArjMapper:zoomIn()
        T.check(ArjMapper.config.wildZoom > zoom, "wilderness zoom increased")
        checkMarkers("zoom in")
        ArjMapper:zoomOut()
        T.check(math.abs(ArjMapper.config.wildZoom - zoom) < .001, "wilderness zoom restored")
        checkMarkers("zoom out")
    end}
})
