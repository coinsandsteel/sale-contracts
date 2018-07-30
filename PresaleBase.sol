pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/ownership/HasNoEther.sol';
import './../STL.sol';

contract PresaleBase is HasNoEther {
    uint constant internal MAX_PURCHASE_AMOUNT_PER_REQUEST = 20;
    uint constant internal TOKEN_CONVERSION_RATE = 400000;

    struct Price {
        uint currentPrice;
        uint priceIncreaseModifier;
        uint basePriceIncrease;
    }

    struct Purchase {
        uint quantity;
        uint roll;
    }

    mapping(address => mapping(address => bool)) referalUsed;
    mapping(bytes32 => Price) private lotPrice;
    mapping(bytes32 => uint) private totalSold;
    mapping(bytes32 => uint) internal lotsForPurchase;
    mapping(address => mapping(bytes32 => Purchase)) internal purchases;
    mapping(address => bytes32[]) internal purchasesIndex;

    address internal bankWallet;
    STL internal tokenContract;

    constructor(address bankWallet_) public {
        bankWallet = bankWallet_;
    }

    // modifiers
    modifier lotExists(bytes32 id) {
        require(lotsForPurchase[id] != 0);
        _;
    }

    modifier lotNotExists(bytes32 id) {
        require(lotsForPurchase[id] == 0);
        _;
    }

    function addPrice(bytes32 id, uint startPrice, uint priceIncreaseModifier, uint basePriceIncrease) internal {
        lotPrice[id] = Price(startPrice, priceIncreaseModifier, basePriceIncrease);
    }

    function getCurrentPrice(bytes32 id) internal view returns(uint) {
        return lotPrice[id].currentPrice;
    }

    function getTotalSold(bytes32 id) internal view returns(uint) {
        return totalSold[id];
    }

    function isUsedReferal(address referalGiver, address refUser) internal view returns(bool) {
        return referalUsed[referalGiver][refUser];
    }

    function useReferal(address referalGiver, address refUser) internal {
        referalUsed[referalGiver][refUser] = true;
    }

    function setTotalSold(bytes32 id, uint value) internal {
        totalSold[id] = value;
    }

    function setCurrentPrice(bytes32 id, uint price) internal {
        lotPrice[id].currentPrice = price;
    }

    event TokensMinted(address user, uint tokens);

    function mintTokens(address receiver, uint ethTotal) internal {
        uint stl = ethTotal / TOKEN_CONVERSION_RATE;
        tokenContract.mint(receiver, stl);
        emit TokensMinted(receiver, stl);
    }

    function setTokenContract(STL tokenContract_) public onlyOwner {
        tokenContract = tokenContract_;
    }

    // ceiling(log2(n))
    // credits to https://ethereum.stackexchange.com/a/30168
    function log(uint x) internal pure returns (uint y) {
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }

    function getPriceIncrease(bytes32 id, uint totalSold_) internal view returns(uint) {
        uint basePriceInc = lotPrice[id].basePriceIncrease;
        return basePriceInc * log(totalSold_) * (lotPrice[id].priceIncreaseModifier / 10000) + basePriceInc;
    }

    function getPricesForNextItems(bytes32 lotId, uint lookAhead) external view returns(uint[] prices, uint guaranteeSurcharge) {
        uint currentPrice = getCurrentPrice(lotId);
        uint totalSold_ = getTotalSold(lotId) + lookAhead;
        prices = new uint[](MAX_PURCHASE_AMOUNT_PER_REQUEST);
        for (uint i = 0; i < MAX_PURCHASE_AMOUNT_PER_REQUEST; ++i) {
            prices[i] = currentPrice;
            totalSold_++;
            currentPrice += getPriceIncrease(lotId, totalSold_);
        }

        for (i = 0; i < 10; ++i) {
            guaranteeSurcharge += getPriceIncrease(lotId, totalSold_);
        }
    }

    // return lot ids, amounts
    function getPurchasedItems() external view returns(bytes32[] itemsOwned, uint[] ownedAmounts) {
        itemsOwned = purchasesIndex[msg.sender];
        ownedAmounts = new uint[](itemsOwned.length);

        for (uint i = 0; i < itemsOwned.length; ++i) {
            ownedAmounts[i] = purchases[msg.sender][itemsOwned[i]].quantity;
        }
    }
}