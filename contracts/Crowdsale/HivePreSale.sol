pragma solidity ^0.4.18;

import "../Token/SafeMath.sol";
import "../Token/Hive.sol";

contract HivePreSale {

    using SafeMath for uint256;
    // The token being sold
    Hive public token;

    // Address where funds are collected
    address public vaultWallet;

    // How many token units a buyer gets per wei
    uint256 public hivePerEther;

    // How much hive cost per USD
    uint256 public hivePerUSD;

    // Owner of this contract
    address public owner;

    //Flag paused sale
    bool public paused;

    uint256 public openingTime;
    uint256 public closingTime;

    uint256 public minimumWei;

    /**
    * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime && paused == false);
        _;
    }

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function HivePreSale(uint256 _hivePerEther, address _vaultWallet, Hive _token, uint256 _openingTime, uint256 _closingTime) public {
        hivePerEther = _hivePerEther;
        vaultWallet = _vaultWallet;
        token = _token;
        owner = msg.sender;
        openingTime = _openingTime;
        closingTime = _closingTime;
        paused = false;
        hivePerUSD = 500; //each hive is 0.002$
        minimumWei = 100000000000000000; //0.1 Ether
    }

    function () external payable {
        buyTokens(msg.sender);
    }
    
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }


    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable onlyWhileOpen {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        _verifyAvailability(tokens);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _forwardFunds();
    }

    function changeRate(uint256 _newRate) onlyOwner public {
        require(_newRate > 0);
        hivePerEther = _newRate;
    }

    function changeMinimumWei(uint256 _newMinimumWei) onlyOwner public {        
        minimumWei = _newMinimumWei;
    }

    function extendSale(uint256 _newClosingTime) onlyOwner public {
        require(_newClosingTime > closingTime);
        closingTime = _newClosingTime;
    }

    function haltSale() onlyOwner public {
        paused = true;
    }

    function resumeSale() onlyOwner public {
        paused = false;
    }

    //Called from outside to auto handle BTC and FIAT purchases
    function forwardTokens(address _beneficiary, uint256 totalTokens) onlyOwner onlyWhileOpen public {        
        _preValidateTokenTransfer(_beneficiary, totalTokens);
        _deliverTokens(_beneficiary, totalTokens);
    }

    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function changeVaultWallet(address _newVaultWallet) onlyOwner public {
        require(_newVaultWallet != address(0));
        vaultWallet = _newVaultWallet;
    }

    //Called after the sale ends to withdraw remaining unsold tokens
    function withdrawUnsoldTokens() onlyOwner public {    
        uint256 unsold = token.balanceOf(this);
        token.transfer(owner, unsold);
    }

    function terminate() public onlyOwner {
        selfdestruct(owner);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(hasClosed() == false);
        require(paused == false);
        require(_beneficiary != address(0));
        require(_weiAmount >= minimumWei);
    }

    /**
    * @dev Validation of a token transfer, used with BTC purchase.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number to tokens to transfer
    */
    function _preValidateTokenTransfer(address _beneficiary, uint256 _tokenAmount) internal view {
        require(hasClosed() == false);
        require(paused == false);
        require(_beneficiary != address(0));
        require(_tokenAmount > 0);
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) private {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) private {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
  

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
        return _weiAmount.mul(hivePerEther);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() private {
        vaultWallet.transfer(msg.value);
    }

    function _verifyAvailability(uint256 _requestedAmount) private view {
        uint256 remaining = token.balanceOf(this);
        require(remaining >= _requestedAmount);
    }
}