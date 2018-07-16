pragma solidity ^0.4.18 ;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function contractSpend(address _from, uint256 _value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function owner() public view returns (address);
    function bonusRateOneEth() public view returns (uint256);
    function unitsOneEthCanBuy() public view returns (uint256);
}

contract ContractiumWatchdog is Ownable {

    using SafeMath for uint256;

    ContractiumInterface ctuContract;
    address public constant WATCHDOG = 0xC19174dA6216f07EEa585f760fa06Ed19eC27fDc;
    address public constant CONTRACTIUM = 0x0dc319Fa14b3809ea2f0f9Ae28311f957a9bE4a3;
    address public ownerCtuContract;
    address public owner;

    uint8 public constant decimals = 18;
    uint256 public unitsOneEthCanBuy = 15000;
    uint256 public bonusRateOneEth = 0;


    function() public payable {

        require(msg.sender != owner);

        // number of tokens to sale in wei
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);

        // amount of bonus tokens
        uint256 amountBonus = msg.value.mul(bonusRateOneEth);
        
        // amount with bonus value
        amount = amount.add(amountBonus);

        // offering validation
        uint256 remain = ctuContract.balanceOf(ownerCtuContract);
        require(remain >= amount);

        address _from = ownerCtuContract;
        address _to = msg.sender;
        ctuContract.transferFrom(_from, _to, amount);
    

        //Transfer ether to CONTRACTIUM and  WATCHDOG
        uint256 oneTenth = msg.value.div(10);
        uint256 nineTenth = msg.value.sub(oneTenth);

        WATCHDOG.transfer(oneTenth);
        ownerCtuContract.transfer(nineTenth);  
                              
    }

    constructor() public {
        ctuContract =  ContractiumInterface(CONTRACTIUM);
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
        unitsOneEthCanBuy = ctuContract.unitsOneEthCanBuy();
        owner = msg.sender;
    }
    
    function setCtuContract(address _ctuAddress) public onlyOwner {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
        unitsOneEthCanBuy = ctuContract.unitsOneEthCanBuy();
    }

    function setRateAgain() public onlyOwner {
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
    }

    function transferOwnership(address _addr) public onlyOwner{
        super.transferOwnership(_addr);
    }

}
