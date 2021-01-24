// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

interface TokenContractInterface {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

/**
 * @dev From OpenZeppelin contracts 
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
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

/**
 * @dev Lottery contract.
 * 
 * Reusable, time depending lottery.
 * 
 * Mechanics: 
 * Round starts after close time was set. Lottery has common prize fund, which will be taken 
 * by last participant of the lottery. After any bet will be made current round close time will be 
 * delayed by some time (it is a dynamic parameter). Bet amount is fixed parameter, so any participant 
 * will bet the same amount of tokens. 
 * Next round cannot be started until prize fund of last round is not withdrawed. 
 * 
 * Dynamic parameters: 
 *      - token contract (balanceOf, allowance, transferFrom methods must be implemented)
 *      - bet amount
 *      - bet time (current round close time) delay
 *      - next round close time
 */
contract Lottery is Ownable {
    using SafeMath for uint256;

    string public name = "Lottery";
    string public symbol = "LTTR";

    TokenContractInterface _tokenContract;

    address internal _lastInvestorAddress;
    uint256 internal _lastInvestedTime; // timestamp (secs)

    uint256 internal _betAmount; 
    uint256 internal _prizeFund;

    uint256 internal _roundCloseTime;  // timestamp (secs)
    uint256 internal _betTimeDelay;  // relative time (secs)


    event BetPlaced(address player, uint256 bet);
    event PrizeWasTaken(address winner, uint256 amount);
    event NewRoundStarted(uint256 time, uint256 bet);


    constructor(address tokenAddress) Ownable() {
        _tokenContract = TokenContractInterface(tokenAddress);
        _betAmount = 10 * 1e6;
        _roundCloseTime = block.timestamp;
        _betTimeDelay = 5 minutes;
    }


    /**
     * @dev Make a bet and transfer tokens to this contract. Bet will go to common prize fund. 
     */
    function bet() public {
        require(isRoundActive(), "Round must be active");
        require(_tokenContract.balanceOf(msg.sender) >= _betAmount, "Sender has not enough balance");
        require(_tokenContract.allowance(msg.sender, address(this)) >= _betAmount, "Lottery contract is not allowed to transfer tokens");

        emit BetPlaced(msg.sender, _betAmount);

        _tokenContract.transferFrom(msg.sender, address(this), _betAmount);

        _prizeFund.add(_betAmount);
        _lastInvestedTime = block.timestamp;
        _lastInvestorAddress = msg.sender;
        _roundCloseTime = _roundCloseTime + _betTimeDelay;

    }

    /**
     * @dev Send prize fund to the winner. Clear up info about last round.
     */
    function sendPrize() public {
        require(!isRoundActive(), "Round must be finished");
        require(_prizeFund > 0, "Prize fund is empty");

        emit PrizeWasTaken(_lastInvestorAddress, _prizeFund);

        _tokenContract.transferFrom(address(this), _lastInvestorAddress, _prizeFund);

        _prizeFund = 0;
        _lastInvestedTime = 0;
        _lastInvestorAddress = address(0);
        
    }

    /**
     * @dev Set up parameters for new round and start it. Only for owner 
     */
    function startNewRound(uint256 newRoundCloseTime, uint256 newBetTimeDelay, uint256 newBetAmount) public onlyOwner {
        require(!isRoundActive(), "Round must be finished");
        require(_prizeFund > 0, "Prize fund must be empty first");
        require(newRoundCloseTime > block.timestamp, "Close time must be greater than now");
        require(newBetAmount >= 1 * 1e6, "Bet must be greater or equal than 1 * 1e6");
        require(newBetTimeDelay >= 60, "Time delay must be greater than 1 minute");

        emit NewRoundStarted(block.timestamp, newBetAmount);

        _roundCloseTime = newRoundCloseTime;
        _betAmount = newBetAmount;
        _betTimeDelay = newBetTimeDelay;
    }

    /**
     * @dev Returns timestamp of last bet
     */
    function lastInvestedTime() public view returns(uint256) {
        return _lastInvestedTime;
    }

    /**
     * @dev Returns prize fund of current round
     */
    function prizeFund() public view returns(uint256) {
        return _prizeFund;
    }

    /**
     * @dev Returns current round finish time
     */
    function roundCloseTime() public view returns(uint256) {
        return _roundCloseTime;
    }

    /**
     * @dev Returns bet time delay (is secs)
     */
    function betTimeDelay() public view returns(uint256) {
        return _betTimeDelay;
    }

    /**
     * @dev Returns lottery status - is it active or not
     */
    function isRoundActive() public view returns(bool) {
        return block.timestamp >= _roundCloseTime;
    }

}
