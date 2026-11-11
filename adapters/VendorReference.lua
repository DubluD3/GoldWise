local _, addon = ...

function addon.vendorReference(itemId)
    if type(C_Item) ~= "table" or type(issecretvalue) ~= "function" then
        return nil
    end
    local ok, _, _, _, _, _, _, _, _, _, _, sellPrice = pcall(C_Item.GetItemInfo, itemId)
    if not ok then
        return nil
    end
    local checked, secret = pcall(issecretvalue, sellPrice)
    if checked and secret == false and type(sellPrice) == "number" and sellPrice >= 0
        and sellPrice < 2 ^ 53 and sellPrice % 1 == 0 then
        return sellPrice
    end
end
