local addonName, T = ...
T.actionCamCVars = {} -- todo: non global assignment?
for key, command in pairs((ConsoleGetAllCommands and ConsoleGetAllCommands()) or (C_Console and C_Console.GetAllCommands())) do
  if (command.commandType == 0 and strfind(command.command, 'test_camera') ~= nil) then
      table.insert(T.actionCamCVars, command.command)
  end
end
