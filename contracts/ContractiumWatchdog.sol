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
    function currentTotalTokenOffering() public view returns (uint256);
    function currentTokenOfferingRaised() public view returns (uint256);

    function isOfferingStarted() public view returns (bool);
    function offeringEnabled() public view returns (bool);
    function startTime() public view returns (uint256);
    function endTime() public view returns (uint256);
}


contract ContractiumWatchdog is Ownable {

    using SafeMath for uint256;

    ContractiumInterface ctuContract;
    address public constant WATCHDOG = 0x3c99c11AEA3249EE2B80dcC0A7864dCC2b54be78;
    address public constant CONTRACTIUM = 0x0dc319Fa14b3809ea2f0f9Ae28311f957a9bE4a3;
    address public ownerCtuContract;
    address public owner;

    uint8 public constant decimals = 18;
    uint256 public unitsOneEthCanBuy = 15000;
    uint256 public bonusRateOneEth;
    uint256 public currentTotalTokenOffering;
    uint256 public currentTokenOfferingRaised;

    bool public isOfferingStarted;
    bool public offeringEnabled;
    uint256 public startTime;
    uint256 public endTime;


    function() public payable {

        require(msg.sender != owner);

        // Number of tokens to sale in wei
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);

        // Amount of bonus tokens
        uint256 amountBonus = msg.value.mul(bonusRateOneEth);
        
        // Amount with bonus value
        amount = amount.add(amountBonus);

        // Offering validation
        uint256 remain = ctuContract.balanceOf(ownerCtuContract);
        require(remain >= amount);
        preValidatePurchase(amount);

        address _from = ownerCtuContract;
        address _to = msg.sender;
        ctuContract.transferFrom(_from, _to, amount);

        currentTokenOfferingRaised = currentTokenOfferingRaised.add(amount);  

        //Transfer ether to CONTRACTIUM and  WATCHDOG
        uint256 oneTenth = msg.value.div(10);
        uint256 nineTenth = msg.value.sub(oneTenth);

        WATCHDOG.transfer(oneTenth);
        ownerCtuContract.transfer(nineTenth);  
                              
    }

    constructor() public {
        ctuContract =  ContractiumInterface(CONTRACTIUM);
        ownerCtuContract = ctuContract.owner();
        owner = msg.sender;

        bonusRateOneEth = ctuContract.bonusRateOneEth();
        currentTotalTokenOffering = ctuContract.currentTotalTokenOffering();
        
        isOfferingStarted = ctuContract.isOfferingStarted();
        offeringEnabled = ctuContract.offeringEnabled();
        startTime = ctuContract.startTime();
        endTime = ctuContract.endTime();
    }

    /**
    * @dev Validate before purchasing.
    */
    function preValidatePurchase(uint256 _amount) internal {
        require(_amount > 0);
        require(isOfferingStarted);
        require(offeringEnabled);
        require(currentTokenOfferingRaised.add(ctuContract.currentTokenOfferingRaised().add(_amount)) <= currentTotalTokenOffering);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
    }
    
    /**
    * @dev Set Contractium address and related parameter from Contractium Smartcontract.
    */
    function setCtuContract(address _ctuAddress) public onlyOwner {
        require(_ctuAddress != address(0x0));

        ctuContract = ContractiumInterface(_ctuAddress);
        ownerCtuContract = ctuContract.owner();

        bonusRateOneEth = ctuContract.bonusRateOneEth();
        currentTotalTokenOffering = ctuContract.currentTotalTokenOffering();

        isOfferingStarted = ctuContract.isOfferingStarted();
        offeringEnabled = ctuContract.offeringEnabled();
        startTime = ctuContract.startTime();
        endTime = ctuContract.endTime();
    }

    /**
    * @dev Set related parameter from Contractium Smartcontract again.
    */
    function setRateAgain() public onlyOwner {
        ownerCtuContract = ctuContract.owner();

        bonusRateOneEth = ctuContract.bonusRateOneEth();
        currentTotalTokenOffering = ctuContract.currentTotalTokenOffering();

        isOfferingStarted = ctuContract.isOfferingStarted();
        offeringEnabled = ctuContract.offeringEnabled();
        startTime = ctuContract.startTime();
        endTime = ctuContract.endTime();
    }

    /**
    * @dev Reset current token offering raised for new Sale.
    */
    function resetCurrentTokenOfferingRaised() public onlyOwner {
        currentTokenOfferingRaised = 0;
    }

    function transferOwnership(address _addr) public onlyOwner{
        super.transferOwnership(_addr);
    }

}
