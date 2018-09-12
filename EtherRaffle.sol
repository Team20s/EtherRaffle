pragma solidity ^0.4.24;

contract EtherRoulette{
    struct winner{
        uint round;
        uint winnerNumber;
        uint prize;
    }
    
    address[] participatient;
    uint round;
    uint timedeadline;
    uint prize;
    uint fee;
    address owner;
    mapping (address => uint[]) public purchasedNumber;
    winner[] public lastWinners;
    
    event Win(uint round, uint winner, uint prize);
    event Purchase(uint number, uint prize);
    event TimeChange(uint time);
    event FeeChange(uint fee);
    event Widthdraw(uint balance);
    
    constructor() public{
        owner = msg.sender;
        timedeadline = now + 1 days;
        round = 1;
        fee = 2;
    }
    
    modifier onlyowner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier checkTimeOut(){
        require(now < timedeadline - 1 hours);
        _;
    }
    
    modifier gameEnd(){
        require(now > timedeadline);
        _;
    }
    
    function() payable public{
        require(now < timedeadline - 1 hours);
        require(msg.value >= 1 ether);
        
        uint amount = msg.value;
        amount -= 1 ether;
        participatient.push(msg.sender);
        purchasedNumber[msg.sender].push(participatient.length-1);
        
        if(amount > 0){
            msg.sender.transfer(amount);
        }
        prize += 1 ether;
        
        emit Purchase(participatient.length-1, prize / 1 ether);
    }
    
    function winning() gameEnd onlyowner returns (uint){
        uint winnerNumber = now % participatient.length;
        
        uint _fee = prize * fee / 100;
        prize -= _fee;
        
        //owner.transfer(_fee);
        participatient[winnerNumber].transfer(prize);
        
        
        lastWinners.push(winner({
            round: round,
            winnerNumber: winnerNumber,
            prize: prize
        }));
        
        emit Win(round, winnerNumber, prize / 1 ether);
        
        newGame();
        return winnerNumber;
    }
    
    function history(uint _round) view returns (uint, uint, uint){
        winner lastGame = lastWinners[_round];
        return (lastGame.round, lastGame.winnerNumber, lastGame.prize);
    }
    
    function getBalance() view returns(uint){
        return this.balance - prize;
    }
    
    function finish() onlyowner{
        timedeadline = now;
    }
    
    function checkNumber() view returns(uint[]){
        return purchasedNumber[msg.sender];
    }
    
    function changeTime(uint time) onlyowner{
        timedeadline = time;
        emit TimeChange(timedeadline);
    }
    
    function changeFee(uint _fee) onlyowner{
        fee = _fee;
        emit FeeChange(fee);
    }
    
    function newGame() onlyowner gameEnd{
        timedeadline = now + 1 days;
        round += 1;
        prize = 0;
        
        for(uint i = 0; i < participatient.length; ++i){
            delete purchasedNumber[participatient[i]];
        }
        
        delete participatient;
    }
    
    function get() view returns(address[], uint, uint, uint, uint, address){
        return (participatient, round, timedeadline, prize / 1 ether, fee, owner);
    }
    
    function withdraw(uint amount) onlyowner{
        uint balance = getBalance();
        require(balance> amount);
        owner.transfer(amount);
        Widthdraw(balance-amount);
    }
}