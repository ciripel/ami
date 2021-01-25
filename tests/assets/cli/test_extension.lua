local optionList, command, _, _ = ...

if type(command) == "table" and command.id == "return" then
    return optionList.value
end