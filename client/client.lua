-- Create a table to store blips for each group member
local GroupPlayerBlips = {}

-- Helper function to validate the member's ID
local function validateMemberId(args)
    -- Try to convert the first argument to a number
    local memberId = tonumber(args[1])
    -- Check if memberId is not nil and the player is not the sender itself
    if memberId and GetPlayerFromServerId(memberId) ~= PlayerId() then
        return memberId
    end
    return nil
end

-- Helper function to create a blip for a member
local function createBlip(memberId, dataMember)
    -- Get the in-game id of the player
    local playerId = GetPlayerFromServerId(memberId)
    -- If the player does not exist, return
    if playerId == -1 then
        return
    end

    -- Get the ped of the player
    local memberPed = GetPlayerPed(playerId)
    -- Create a blip for the ped
    local blip = BlipAddForEntity(GetHashKey("BLIP_STYLE_OBJECTIVE"), memberPed)

    -- If the member is a leader, set the blip sprite to leader's sprite
    if dataMember.type == 'leader' then
        SetBlipSprite(blip, Config.sprite.leader, 1)
    else
        -- Else set the blip sprite to member's sprite
        SetBlipSprite(blip, Config.sprite.members, 1)
    end

    -- Set the scale and name of the blip
    SetBlipScale(blip, 1.0)
    SetBlipName(blip, dataMember.PlayerName)
    -- Add a color modifier to the blip
    BlipAddModifier(blip, joaat(Config.blipsColor))
    -- Store the blip in the GroupPlayerBlips table
    GroupPlayerBlips[memberId] = blip
end

-- Helper function to remove all blips
local function removeBlips()
    -- For each blip in the GroupPlayerBlips, remove it
    for _, blip in pairs(GroupPlayerBlips) do
        RemoveBlip(blip)
    end
end

-- Command to invite a player to a group
RegisterCommand('inviteGroup', function(source, args)
    -- Validate the member id
    local memberId = validateMemberId(args)
    if memberId then
        -- If valid, trigger the server event to add the member to the group
        TriggerServerEvent('elz_groupmaker:AddMemberToGroup', memberId)
    else
        -- If not valid, show the usage of the command
        TriggerEvent('chatMessage', "GROUP", { 123, 196, 255 },"Usage : /inviteGroup [CHAR_ID and NOT YOU]" )
    end
end, false)

-- Event to add a blip for a new player in the group
RegisterNetEvent('elz_groupmaker:AddBlipForPlayer')
AddEventHandler('elz_groupmaker:AddBlipForPlayer', createBlip)

-- Command to remove a player from the group
RegisterCommand('removeGroup', function(source, args)
    -- Validate the member id
    local memberId = validateMemberId(args)
    if memberId then
        -- If valid, trigger the server event to remove the member from the group
        TriggerServerEvent('elz_groupmaker:removeMemberFromGroup', memberId)
    else
        -- If not valid, show the usage of the command
        TriggerEvent('chatMessage', "GROUP", { 123, 196, 255 },"Usage : /removeGroup [CHAR_ID and NOT YOU]" )
    end
end, false)

-- Event to remove the blip of a player when they leave the group
RegisterNetEvent('elz_groupmaker:RemoveBlipForPlayer')
AddEventHandler('elz_groupmaker:RemoveBlipForPlayer', function(memberIdToRemove)
    if GroupPlayerBlips[memberIdToRemove] then
        print("Blip exists. Removing: ", GroupPlayerBlips[memberIdToRemove])
        RemoveBlip(GroupPlayerBlips[memberIdToRemove])
        GroupPlayerBlips[memberIdToRemove] = nil
    end
end)

-- Command to delete the group
RegisterCommand('deleteGroup', function()
    TriggerServerEvent('elz_groupmaker:deleteGroup')
end, false)

-- Event to remove all blips when the group is deleted
RegisterNetEvent('elz_groupmaker:RemoveAllBlips')
AddEventHandler('elz_groupmaker:RemoveAllBlips', removeBlips)

-- Event to remove all blips when the resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    removeBlips()
end)

-- Event triggered when a player disconnects
AddEventHandler('vorp:playerDropped', function(user)
    local source = user.get('source')
    local sourceStr = tostring(source)

    -- Check each group for the disconnected player
    for groupId, group in pairs(groupData) do
        if group[sourceStr] then
            -- If the disconnected player is in the group, remove them
            groupData[groupId][sourceStr] = nil

            -- Update the group for each member and remove blips for the disconnected player
            for memberId, _ in pairs(groupData[groupId]) do
                TriggerClientEvent('elz_groupmaker:receiveUpdatedGroup', tonumber(memberId),
                    groupData[groupId])
                TriggerClientEvent('elz_groupmaker:RemoveBlipForPlayer', tonumber(memberId), source)
            end
        end

        -- If the disconnected player was a leader of a group, delete the group
        if groupId == sourceStr then
            HandleDeleteGroup(source)
        end
    end
end)

