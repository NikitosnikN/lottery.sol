## Lottery contract.

Reusable, time depending lottery.

### Mechanics: 

Round starts after close time was set. Lottery has common prize fund, which will be taken by last participant of the lottery. 

After any bet will be made current round close time will be delayed by some time (it is a dynamic parameter). Bet amount is fixed parameter, so any participant 
will bet the same amount of tokens. 

Next round cannot be started until prize fund of last round is not withdrawed. 

### Dynamic parameters: 

- token contract (balanceOf, allowance, transferFrom methods must be implemented)
- bet amount
- bet time (current round close time) delay
- next round close time