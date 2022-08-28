actionCamCVars = {} -- todo: non global assignment?
for key, command in pairs(C_Console.GetAllCommands()) do
  if (command.commandType == 0 and strfind(command.command, 'test_camera') ~= nil) then
      table.insert(actionCamCVars, command.command)
  end
end
