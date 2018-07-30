pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/ownership/rbac/RBAC.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract AccessControl is RBAC, Ownable {
    string constant internal ITEM_CREATOR = "item-creator";
    string constant internal TOKEN_MINTER = "token-minter";

    function adminAddRole(address addr, string role) public onlyOwner {
        addRole(addr, role);
    }
}