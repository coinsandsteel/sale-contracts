pragma solidity ^0.4.23;
import './Random.sol';
import './PresaleBase.sol';

// Support erc721 metadata to transfer data to loomchain

contract ChestPresale is Random, PresaleBase {
    struct ChestLot {
        bytes32 id; 
        uint endOfSale;
    }

    ChestLot[] private lots;

    constructor(address wallet) PresaleBase(wallet) public {

    }

    function addLot(bytes32 id, uint startPrice, uint priceIncreaseModifier, uint basePriceIncrease, uint endOfSale) 
        lotNotExists(id)
        public 
        onlyOwner 
    {
        lotsForPurchase[id] = lots.push(ChestLot(id, endOfSale));
        addPrice(id, startPrice, priceIncreaseModifier, basePriceIncrease);
    }

    function getTotalLots() 
        public 
        view 
        returns(uint) 
    {
        return lots.length;
    }

    function getLot(uint idx) 
        external 
        view 
        returns(
            bytes32 id, 
            uint totalSold, 
            uint currentPrice, 
            uint endOfSale
        ) 
    {
        id = lots[idx].id;
        totalSold = getTotalSold(id);
        currentPrice = getCurrentPrice(id);
        endOfSale = lots[idx].endOfSale;
    }

    event LogPurchase(bytes32 chest, uint newPrice, uint totalSold);

    function purchase(bytes32[] ids, uint[] amounts, address referral) 
        external 
        payable
    {
        require(msg.sender != address(0));

        uint totalPrice = 0;
        bool allowReferralBonus = true;
        for (uint i = 0; i < ids.length; ++i) {
            bytes32 lotId = ids[i];
            
            if (lotId != "common") {
                allowReferralBonus = true;
            }

            uint lotIdx = lotsForPurchase[lotId];
            // if chest does exist
            require(lotIdx != 0);
            // put limit to avoid spam and gas block limit
            require(amounts[i] > 0 && amounts[i] <= MAX_PURCHASE_AMOUNT_PER_REQUEST);
            lotIdx -= 1;
            // if lot still valid
            require(now < lots[lotIdx].endOfSale);

            uint currentPrice = getCurrentPrice(lotId);
            Purchase storage purchasedChests = purchases[msg.sender][lotId];
            // create random seed if first time purchase
            if (purchasedChests.roll == 0) {
                purchasedChests.roll = random(msg.sender, currentPrice);
                purchasesIndex[msg.sender].push(lotId);
            }

            // increase total eth to pay
            uint totalSold = getTotalSold(lotId);
            for (uint j = 0; j < amounts[i]; ++j) {
                totalPrice += currentPrice;
                totalSold++;
                currentPrice += getPriceIncrease(lotId, totalSold);
            }

            // save and log
            purchasedChests.quantity += amounts[i];
            setCurrentPrice(lotId, currentPrice);
            setTotalSold(lotId, totalSold);

            emit LogPurchase(lotId, currentPrice, totalSold);
        }
        
        require(msg.value >= totalPrice);

        if (msg.value > totalPrice) {
            msg.sender.transfer(msg.value - totalPrice);
        }

        bankWallet.transfer(totalPrice);
        
        Purchase storage referralChest = purchases[referral]["rare"];
        if (
            allowReferralBonus &&
            purchases[referral]["rare"].quantity > 0 &&
            purchases[referral]["legendary"].quantity > 0 &&
            referral != address(0) && 
            msg.sender != referral && 
            !isUsedReferal(msg.sender, referral)
        ) {
            useReferal(msg.sender, referral);
            // give to both rare chest
            if (referralChest.roll == 0) {
                referralChest.roll = random(msg.sender, currentPrice);
                purchasesIndex[referral].push("rare");
            }
            referralChest.quantity++;
            purchases[msg.sender]["rare"].quantity++;
        }

        mintTokens(msg.sender, totalPrice);
    }
}
