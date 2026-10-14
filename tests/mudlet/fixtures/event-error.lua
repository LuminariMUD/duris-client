registerAnonymousEventHandler("DurisTestError", function() error("DELIBERATE_EVENT_FAILURE") end)
raiseEvent("DurisTestError")
