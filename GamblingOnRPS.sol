// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Choice { None, Rock, Paper, Scissors }
    
    address public player1;
    address public player2;
    
    bytes32 public player1Commit;
    Choice public player1Choice;
    bytes32 public player2Commit;
    Choice public player2Choice;
    
    uint256 public betAmount;
    uint256 public timeout;
    
    event PlayerJoined(address indexed player);
    event PlayerCommitted(address indexed player);
    event GameResult(address indexed winner, uint256 amount);
    event GameReset();
    
    constructor(uint256 _timeout) {
        timeout = _timeout;
    }
    
    function joinGame(bytes32 _commit) public payable {
        require(player1 == address(0) || player2 == address(0), "Game is full");
        require(msg.value > 0, "Must send some Ether to join");
        
        if (player1 == address(0)) {
            player1 = msg.sender;
            player1Commit = _commit;
            betAmount = msg.value;
        } else {
            player2 = msg.sender;
            player2Commit = _commit;
            require(msg.value == betAmount, "Must send the same amount as player 1");
        }
        
        emit PlayerJoined(msg.sender);
    }
    
    function revealChoice(Choice _choice, string memory _secret) public {
        require(_choice != Choice.None, "Invalid choice");
        require(msg.sender == player1 || msg.sender == player2, "Not a player");
        
        bytes32 commit = keccak256(abi.encodePacked(_choice, _secret));
        
        if (msg.sender == player1 && commit == player1Commit) {
            player1Choice = _choice;
        } else if (msg.sender == player2 && commit == player2Commit) {
            player2Choice = _choice;
        } else {
            revert("Commit and choice do not match");
        }
        
        emit PlayerCommitted(msg.sender);
        
        if (player1Choice != Choice.None && player2Choice != Choice.None) {
            determineWinner();
        }
    }
    
    function determineWinner() internal {
        int winner = int(player1Choice) - int(player2Choice);
        if (winner == 0) {
            // It's a tie, refund the players
            payable(player1).transfer(betAmount);
            payable(player2).transfer(betAmount);
            emit GameResult(address(0), 0);
        } else if (winner == 1 || winner == -2) {
            // Player 1 wins
            payable(player1).transfer(betAmount * 2);
            emit GameResult(player1, betAmount * 2);
        } else {
            // Player 2 wins
            payable(player2).transfer(betAmount * 2);
            emit GameResult(player2, betAmount * 2);
        }
        
        // Reset the game
        resetGame();
    }
    
    function resetGame() internal {
        player1 = address(0);
        player2 = address(0);
        player1Commit = 0;
        player1Choice = Choice.None;
        player2Commit = 0;
        player2Choice = Choice.None;
        betAmount = 0;
        
        emit GameReset();
    }
    
    function withdraw() public {
        require(msg.sender == player1 || msg.sender == player2, "Not a player");
        require(block.timestamp >= timeout, "Cannot withdraw before timeout");
        
        if (msg.sender == player1) {
            payable(player1).transfer(betAmount);
        } else {
            payable(player2).transfer(betAmount);
        }
        
        resetGame();
    }
}
