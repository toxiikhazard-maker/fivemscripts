RegisterCommand('raid_stash', function()
    lib.callback.await('zrp_inventory:server:openRaidStash', false)
end)
