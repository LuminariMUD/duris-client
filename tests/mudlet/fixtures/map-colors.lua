local T = DurisTest
ArjUI.initialDataRequested = true

-- Duris AnsiString::ansi() writes &=<background><foreground> and
-- &+<foreground> clears the previous background (src/net/ansi.c).
local map = "&=lB~&+g.&=bY^&+g.&n plain\n"
    .. "&=bY^&+g.&-r &+W@&n reset\n"
    .. "&=bY^\nnext line\n"
    .. "&=bY^\\nlegacy line\n"
    .. "&+lblack&n &=lWwhite&n\n"
    .. "&=bB &+g. water"

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
        T.check(colorAt(name, "~.^.", 0, true) == "0,128,255", "black-background ocean has blue foreground")
        T.check(colorAt(name, "~.^.") == "0,0,0", "black-background ocean has black background")
        T.check(colorAt(name, "~.^.", 2, true) == "255,255,0", "combined code keeps yellow mountain foreground")
        T.check(colorAt(name, "~.^.", 2) == "0,0,60", "combined code keeps blue mountain background")
        T.check(colorAt(name, "~.^.", 3) == bg, "foreground-only terrain clears preceding background")
        T.check(colorAt(name, "^. @", 2) == "80,0,0", "background-only code colors a space")
        T.check(colorAt(name, "^. @", 2, true) == colorAt(name, "reset", 0, true), "background-only code clears previous foreground")
        T.check(colorAt(name, "^. @", 3) == bg, "foreground after background-only code resets background")
        T.check(colorAt(name, "plain") == bg and colorAt(name, "reset") == bg, "reset clears map background")
        T.check(colorAt(name, "next line") == bg and colorAt(name, "legacy line") == bg, "real and legacy newlines clear map background")
        T.check(colorAt(name, "black", 0, true) == "0,0,0", "lowercase black is distinct from bright black")
        T.check(colorAt(name, " . water") == "0,0,60" and colorAt(name, " . water", 1) == bg, "real water-to-plains glyph transition clears blue background")
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
    end}
})
