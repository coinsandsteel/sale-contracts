pragma solidity ^0.4.18;
import './../Random.sol';
import './PresaleBase.sol';

contract ItemsPresale is PresaleBase, Random {
    uint private itemId;

    struct ItemLot {
        bytes32 id; 

        uint endOfSale;
        uint itemType;
    }
    
    ItemLot[] private lots;

    constructor(address wallet) PresaleBase(wallet) public {

    }

    function addLot(
        bytes32 id, 
        uint endOfSale, 
        uint itemType, 
        uint startPrice, 
        uint priceIncreaseModifier, 
        uint basePriceIncrease
    ) 
        lotNotExists(id)
        public 
        onlyOwner 
    {
        lotsForPurchase[id] = lots.push(ItemLot(id, endOfSale, itemType));
        addPrice(id, startPrice, priceIncreaseModifier, basePriceIncrease);
    }

    // getters

    function getTotalLots() 
        public 
        view 
        returns(uint) 
    {
        return lots.length;
    }

    function getLot(uint idx) 
        public 
        view 
        returns(
            bytes32 id,
            uint totalSold,
            uint endOfSale,
            uint price,
            uint itemType
        ) 
    {
        ItemLot storage lot = lots[idx];
        id = lot.id;
        totalSold = getTotalSold(id);
        endOfSale = lot.endOfSale;
        price = getCurrentPrice(id);
        itemType = lot.itemType;
    }

    event LogPurchase(bytes32 item, uint currentPrice, uint totalSold);

    function purchase(bytes32[] ids, uint[] amounts) 
        external 
        payable 
    {
        require(msg.sender != address(0));
        
        uint totalPrice = 0;
        for (uint i = 0; i < ids.length; ++i) {
            bytes32 lotId = ids[i];
            uint lotIdx = lotsForPurchase[lotId];
            // if chest does exist
            require(lotIdx != 0);
            // put limit to avoid spam and gas block limit
            require(amounts[i] > 0 && amounts[i] <= MAX_PURCHASE_AMOUNT_PER_REQUEST);
            lotIdx -= 1;

            ItemLot storage lot = lots[lotIdx];
            // if lot still valid
            require(now < lot.endOfSale);
            
            Purchase storage purchasedItem = purchases[msg.sender][lotId];
            uint price = getCurrentPrice(lotId);
            uint purchasedItemsThisSession = amounts[i];
            uint totalSold = getTotalSold(lotId);

            // is it first purchase?
            if (purchasedItem.roll == 0) {
                // save random seed
                purchasedItem.roll = random(msg.sender, totalSold);
                purchasesIndex[msg.sender].push(lotId);
            }

            while (purchasedItemsThisSession != 0) {
                totalPrice += price;
                totalSold++;
                price += getPriceIncrease(lotId, totalSold);
                purchasedItemsThisSession--;
            }

            purchasedItem.quantity += amounts[i];
            emit LogPurchase(lotId, price, totalSold);

            setCurrentPrice(lotId, price);
            setTotalSold(lotId, totalSold);
        }
        
        require(msg.value >= totalPrice);
        
        // return back funds
        if (msg.value > totalPrice) {
            msg.sender.transfer(msg.value - totalPrice);
        }

        bankWallet.transfer(totalPrice);

        mintTokens(msg.sender, totalPrice);
    }
}