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
    address public constant WATCHDOG = 0x007f29AE7ec8615AcFDA157FAf0ebB7BCcb0937d;
    address public constant CONTRACTIUM = 0x943ACa8ed65FBf188A7D369Cfc2BeE0aE435ee1B;
    address public ownerCtuContract;
    address public owner;

    uint8 public constant decimals = 18;
    uint256 public unitsOneEthCanBuy = 15000;

    //Current token offering raised in ContractiumWatchdogs
    uint256 public currentTokenOfferingRaised;

    function() public payable {

        require(msg.sender != owner);

        // Get bonus rate from Contractium
        uint256 bonusRateOneEth = ctuContract.bonusRateOneEth();

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

        // Transfer token to msg.sender
        address _from = ownerCtuContract;
        address _to = msg.sender;
        require(ctuContract.transferFrom(_from, _to, amount));
        
        // Sum token raised in total
        currentTokenOfferingRaised = currentTokenOfferingRaised.add(amount);  

        //Transfer ether to CONTRACTIUM and WATCHDOG
        uint256 oneTenth = msg.value.div(10);
        uint256 nineTenth = msg.value.sub(oneTenth);

        WATCHDOG.transfer(oneTenth);
        ownerCtuContract.transfer(nineTenth);  
    }

    constructor() public {
        ctuContract = ContractiumInterface(CONTRACTIUM);
        ownerCtuContract = ctuContract.owner();
        owner = msg.sender;
    }

    /**
    * @dev Validate before purchasing.
    * First, get parameters from Contractium Smartcontract.
    * Then, validating.
    */
    function preValidatePurchase(uint256 _amount) internal {
        bool isOfferingStarted = ctuContract.isOfferingStarted();
        bool offeringEnabled = ctuContract.offeringEnabled();
        uint256 startTime = ctuContract.startTime();
        uint256 endTime = ctuContract.endTime();
        uint256 currentTotalTokenOffering = ctuContract.currentTotalTokenOffering();
        uint256 currentTokenOfferingRaisedContractium = ctuContract.currentTokenOfferingRaised();

        require(_amount > 0);
        require(isOfferingStarted);
        require(offeringEnabled);
        require(currentTokenOfferingRaised.add(currentTokenOfferingRaisedContractium.add(_amount)) <= currentTotalTokenOffering);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
    }
    
    /**
    * @dev Set Contractium address and related parameter from Contractium Smartcontract.
    */
    function setCtuContract(address _ctuAddress) public onlyOwner {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        ownerCtuContract = ctuContract.owner();
    }

    /**
    * @dev Reset current token offering raised for new Sale.
    */
    function resetCurrentTokenOfferingRaised() public onlyOwner {
        currentTokenOfferingRaised = 0;
    }
}
