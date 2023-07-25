-- Initialise core and group data variables
local VORPcore = {}
local groupData = {}

-- Get the core information
TriggerEvent('getCore', function(core)
    VORPcore = core
end)

-- Register the server event for adding a member to a group
RegisterServerEvent('elz_groupmaker:AddMemberToGroup')
AddEventHandler('elz_groupmaker:AddMemberToGroup', function(charid)
    local source = source
    local players = GetPlayers()
    local newMemberId = charid

    -- Check if the target player is already a member of another group
    for groupId, group in pairs(groupData) do
        for memberId in pairs(group) do
            if memberId == tostring(charid) then
                -- If the player is already in a group, send a chat message to the inviter
                TriggerClientEvent('chat:addMessage', source, {
                    color = { 123, 196, 255 },
                    multiline = true,
                    args = { "GROUP", _U('IsAlreadyGrouped') }
                })

                return
            end
        end
    end

    -- Prepare data for the group leader
    local leaderData = PreparePlayerData(source, 'leader')

    if leaderData then
        -- Check if the leader has already created a group
        for groupId in pairs(groupData) do
            if groupId == tostring(source) then
                goto continue
            end
        end

        -- Create a new group with the leader as the first member
        local newGroup = {
            [tostring(source)] = leaderData
        }

        -- Add the new group to the group data
        groupData[tostring(source)] = newGroup
    end

    ::continue::

    -- Check each player to see if they are the new member
    for _, player in ipairs(players) do
        if tostring(charid) == player then
            -- Prepare data for the new member
            local memberData = PreparePlayerData(player, 'member')

            if memberData then
                -- Add the new member to the group
                groupData[tostring(source)][tostring(player)] = memberData

                -- Update the group for each member and add blips for the new member
                for memberId, _ in pairs(groupData[tostring(source)]) do
                    TriggerClientEvent('elz_groupmaker:receiveUpdatedGroup', tonumber(memberId),
                        groupData[tostring(source)])
                    if memberId ~= newMemberId then
                        TriggerClientEvent('elz_groupmaker:AddBlipForPlayer', tonumber(memberId), tonumber(newMemberId),
                            memberData)
                        TriggerClientEvent('elz_groupmaker:AddBlipForPlayer', tonumber(newMemberId), tonumber(memberId),
                            groupData[tostring(source)][memberId])
                    end
                end
            end
        end
    end
end)

-- Register the server event for removing a member from a group
RegisterServerEvent('elz_groupmaker:removeMemberFromGroup')
AddEventHandler('elz_groupmaker:removeMemberFromGroup', function(memberToRemoveId)
    local source = source

    -- Check if the leader is trying to remove a member from the group
    if groupData[tostring(source)] and groupData[tostring(source)][tostring(source)].type == 'leader' then
        -- The leader cannot remove himself
        if source ~= memberToRemoveId then
            -- Check if the member to be removed exists in the group
            if groupData[tostring(source)][tostring(memberToRemoveId)] then
                -- Remove all blips for the member to be removed
                TriggerClientEvent('elz_groupmaker:RemoveAllBlips', tonumber(memberToRemoveId))

                -- Remove the member's blip from each other member's map
                for memberId, _ in pairs(groupData[tostring(source)]) do
                    TriggerClientEvent('elz_groupmaker:RemoveBlipForPlayer', tonumber(memberId),
                        tonumber(memberToRemoveId))
                end
                -- Remove the member from the group
                groupData[tostring(source)][tostring(memberToRemoveId)] = nil
            end

            -- Check if the group is empty after removing the member
            local count = 0
            for _ in pairs(groupData[tostring(source)]) do count = count + 1 end
            if count <= 1 then
                -- If the group is empty, delete it
                HandleDeleteGroup(source)
            end
        else
            -- If the leader tries to remove himself, delete the group
            HandleDeleteGroup(source)
        end
    end
end)

-- Function to handle the deletion of a group
function HandleDeleteGroup(source)
    -- Check if the group exists
    if groupData[tostring(source)] then
        -- Remove all blips for each member in the group
        for memberId, _ in pairs(groupData[tostring(source)]) do
            TriggerClientEvent('elz_groupmaker:RemoveAllBlips', tonumber(memberId))
        end
        -- Delete the group
        groupData[tostring(source)] = nil
    end
end

-- Register the server event for deleting a group
RegisterServerEvent('elz_groupmaker:deleteGroup')
AddEventHandler('elz_groupmaker:deleteGroup', function()
    local source = source

    -- Check if the leader is trying to delete the group
    if groupData[tostring(source)] and groupData[tostring(source)][tostring(source)].type == 'leader' then
        -- Remove all blips for each member in the group
        for memberId, _ in pairs(groupData[tostring(source)]) do
            TriggerClientEvent('elz_groupmaker:RemoveAllBlips', tonumber(memberId))
        end
        -- Delete the group
        groupData[tostring(source)] = nil
    end
end)

-- Function to prepare player data
function PreparePlayerData(playerId, playerType)
    -- Get player ped and check if it exists
    local playerPed = GetPlayerPed(playerId)
    if DoesEntityExist(playerPed) then
        -- Get player coordinates
        local coords = GetEntityCoords(playerPed)
        -- Get player character
        local Character = VORPcore.getUser(playerId).getUsedCharacter

        -- Check if the player has a first name (meaning the character exists)
        if Character.firstname then
            -- Prepare player data
            local playername = Character.firstname .. ' ' .. Character.lastname

            return {
                serverId = playerId,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                name = GetPlayerName(playerId),
                PlayerName = playername,
                type = playerType
            }
        end
    end
    return nil
end

-- Event triggered when a player disconnects
AddEventHandler('vorp:playerDropped', function(user)
    local source = user.get('source')
    local sourceString = tostring(source)

    -- Loop through all the groups
    for groupId, group in pairs(groupData) do

        -- Check if the dropped player is in this group
        if group[sourceString] then
            -- Delete player from the group
            group[sourceString] = nil
            -- Inform other group members to remove this player's blip
            for memberId, _ in pairs(group) do
                TriggerClientEvent('elz_groupmaker:RemoveBlipForPlayer', tonumber(memberId), source)
            end

            -- Count the number of remaining members in the group
            local count = 0
            for _ in pairs(group) do count = count + 1 end

            -- If the group has only one member (the leader), delete the group
            if count <= 1 then
                HandleDeleteGroup(groupId)
            end
        end
    end
end)

