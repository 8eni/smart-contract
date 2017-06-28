pragma solidity ^0.4.11;

// Id: 1  AFC Bournemouth
// Id: 2  Arsenal
// Id: 3  Brighton & Hove Albion
// Id: 4  Burnley
// Id: 5  Chelsea
// Id: 6  Crystal Palace
// Id: 7  Everton
// Id: 8  Huddersfield Town
// Id: 9  Leicester City
// Id: 10 Liverpool
// Id: 11 Manchester City
// Id: 12 Manchester United
// Id: 13 Newcastle United
// Id: 14 Southampton
// Id: 15 Stoke City
// Id: 16 Swansea City
// Id: 17 Tottenham Hotspur
// Id: 18 Watford
// Id: 19 West Bromwich Albion
// Id: 20 West Ham United

contract LastManStanding {
    
    address chairperson;
    uint gameWeek;
    uint amount;
    address winner;
    bool entrySuspended;

    function LastManStanding() {
        chairperson = msg.sender;
        gameWeek = 1;
        entrySuspended = false;
    }
    
    modifier chairPerson() {
        if (chairperson != msg.sender) return;
        _;
    }

    struct EntityStruct {
        uint entityTeamId;
        uint entityGameWeek;
        string entityTeamName; // Change to bytes32
        bool isEntityNextRound; // true(After submission) : false(after newEntity || advanceUsersToNextRound)
        bool entityEntered;
        uint entityAmount;
    }
    
    mapping(address => EntityStruct) public entityStructs;
    address[] public entityList;
    uint[] public winners;
    address entityAddress;
    uint usersLeft;
    
    event logString(string);
    event logUint(string, uint);
    event logBool(string, bool);
    event logAddress(string, address);

    
    function isEntity(address entityAddress) public constant returns(bool isIndeed) {
      return entityStructs[entityAddress].entityEntered;
    }
    
    function getUserCount() public constant returns(uint entityCount) {
        return entityList.length;
    }
    
    function newEntry(string entityTeamName, uint entityTeamId) payable public returns (uint rowNumber){
        if (entrySuspended) throw;
        entityAddress = msg.sender;
        if(isEntity(entityAddress)) throw;
        if(gameWeek != 1) throw;
        entityStructs[entityAddress].entityTeamId = entityTeamId;
        entityStructs[entityAddress].entityTeamName = entityTeamName;
        entityStructs[entityAddress].isEntityNextRound = false;
        entityStructs[entityAddress].entityEntered = true;
        entityStructs[entityAddress].entityAmount = msg.value;
        amount += entityStructs[entityAddress].entityAmount; 
        return entityList.push(entityAddress) - 1;
    }
    
    function suspendEntry(bool setEntryAccess) chairPerson public returns (bool _entrySuspended) {
        entrySuspended = setEntryAccess;
        return entrySuspended;
    }
    
    // function getSuspendEntry() constant returns (bool currentSuspendStatus) {
    //     return entrySuspended;
    // }
    
    function advanceUsersToNextRound(uint[] _winners) chairPerson public returns(bool success) {
        winners = _winners;
        gameWeek++;
        usersLeft = 0;
        for (uint8 i = 0; i < entityList.length; i++) { // Roll over addresses
            for (uint8 j = 0; j < winners.length; j++) { // Roll over winner Ids
                if (entityStructs[entityList[i]].entityTeamId == winners[j]) {
                    entityStructs[entityList[i]].isEntityNextRound = true;
                    entityStructs[entityList[i]].entityGameWeek = gameWeek;
                    usersLeft++;
                }
            }
            // logAdvance(entityStructs[entityList[i]].entityTeamName, entityStructs[entityList[i]].isEntityNextRound);
        }
        checkForWinner(usersLeft);
        logUint("Gameweek set to ", gameWeek);
        return true;
    }
    
    function nextUserEntry(string entityTeamName, uint entityTeamId) public returns (bool nextEntryReceived) {
        if (entrySuspended) throw;
        entityAddress = msg.sender;
        if(entityStructs[entityAddress].entityGameWeek != gameWeek && entityStructs[entityAddress].isEntityNextRound != true) throw;
        entityStructs[entityAddress].entityTeamId = entityTeamId;
        entityStructs[entityAddress].entityTeamName = entityTeamName;
        entityStructs[entityAddress].isEntityNextRound = false;
        return true;
    }
    
    function checkForWinner(uint _usersLeft) constant returns (bool weHaveAWinner){
        if(_usersLeft > 1) throw;
        if(_usersLeft == 1) {
            winner = entityList[0];
            logAddress("We have a winner", winner);
        } else {
            logUint("DRAW", _usersLeft);
            for (uint8 i = 0; i < entityList.length; i++) { // Roll over addresses
                entityStructs[entityList[i]].isEntityNextRound = true;
                entityStructs[entityList[i]].entityGameWeek = gameWeek;
            }
        }
        return true;
    }
    
    function getUser(address _address) public constant returns(uint, string, bool, bool, uint, uint) {
        return (entityStructs[_address].entityTeamId,entityStructs[_address].entityTeamName,entityStructs[_address].isEntityNextRound,entityStructs[_address].entityEntered,entityStructs[_address].entityGameWeek,entityStructs[_address].entityAmount);
    }
    
    function getAmount() public constant returns (uint pot) {
        return amount;
    }
    
    function retrievePot() public returns (uint totalPot){  
        if (winner != msg.sender) throw;
        winner.transfer(amount);
        return amount;
    }
    
    function winnerBalance() constant returns (uint winningPot) {
        return winner.balance;
    }

}