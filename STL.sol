pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20/CappedToken.sol';
import './AccessControl.sol';

/**
    ERC20 token, used as in-game currency
 */
contract STL is CappedToken, AccessControl  {
    string public constant name = "STEEEL"; // solium-disable-line uppercase
    string public constant symbol = "STL"; // solium-disable-line uppercase
    uint8 public constant decimals = 9; // solium-disable-line uppercase

    address private bountyWallet;
    uint private constant MAX_SUPPLY = 100000000000000000;
    uint private constant BOUNTY_ALLOCATION = 2; // in %

    constructor(address _bountyWallet) CappedToken(MAX_SUPPLY) public {
        require(_bountyWallet != address(0));
        bountyWallet = _bountyWallet;
        addRole(msg.sender, TOKEN_MINTER);
        mint(bountyWallet, MAX_SUPPLY * BOUNTY_ALLOCATION / 100);
        removeRole(msg.sender, TOKEN_MINTER);
    }

    modifier hasMintPermission() {
        checkRole(msg.sender, TOKEN_MINTER);
        _;
    }
}