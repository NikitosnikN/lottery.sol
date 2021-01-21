// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract Ownable {
    address internal _owner;

    event OwnerTransfered(address owner);

    constructor () {
        _owner = msg.sender;
        emit OwnerTransfered(msg.sender);
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
        emit OwnerTransfered(newOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address comparableAddress) public view returns (bool) {
        return _owner == comparableAddress;
    }

}

contract Lottery is Ownable {
    using SafeMath for uint256;

    string public name = "Lottery";
    string public symbol = "Symbol";

    address internal _lastInvestorAddress;
    uint256 internal _lastInvestedTime;

    uint256 internal _betAmount;
    uint256 internal _roundCloseTime;
    uint256 internal _prizeFund;


    event BetPlaced(address player, uint256 bet);
    event PrizeWasTaken(address winner, uint256 amount);
    event NewRoundStarted(uint256 time, uint256 bet);


    constructor() Ownable() {
        _betAmount = 10 * 1e6;
        _roundCloseTime = block.timestamp;
    }


    function bet() public {
        emit BetPlaced(msg.sender, _betAmount);

        _prizeFund.add(_betAmount);
        _lastInvestedTime = block.timestamp;
        _lastInvestorAddress = msg.sender;
    }



    function getPrize() public {
        require(!isRoundActive(), "Round must be finished");
        require(_prizeFund > 0, "Prize fund is empty");
        require(_lastInvestorAddress == msg.sender, "You must be last investor");

        emit BetPlaced(msg.sender, _prizeFund);

        _prizeFund = 0;
        _lastInvestedTime = 0;
        _lastInvestorAddress = address(0);
        
    }

    function startNewRound(uint256 newRoundCloseTime, uint256 newBet) public onlyOwner {
        require(!isRoundActive(), "Round must be finished");
        require(_prizeFund > 0, "Prize fund must be empty first");
        require(newRoundCloseTime > block.timestamp, "Close time must be greater than now");
        require(newBet >= 1 * 1e6, "Bet must be greater or equal than 1 * 1e6");

        emit NewRoundStarted(block.timestamp, newBet);

        _roundCloseTime = newRoundCloseTime;
        _betAmount = newBet;
    }


    function lastInvestedTime() public view returns(uint256) {
        return _lastInvestedTime;
    }

    function prizeFund() public view returns(uint256) {
        return _prizeFund;
    }

    function roundCloseTime() public view returns(uint256) {
        return _roundCloseTime;
    }

    function isRoundActive() public view returns(bool) {
        return block.timestamp >= _roundCloseTime;
    }

}
