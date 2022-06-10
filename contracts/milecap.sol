// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * @title SwopXPlace
 * @author Anwar (@pcanw)
 * 
 * @dev collact any matches occurs bewteen two users 
 *
*/



// to do: retrun limit per swop and return max by claim

contract place  {
    
    
   using Counters for Counters.Counter;
    Counters.Counter private _timestampId;

    using SetMileStone for SetMileStone.Data; 
    SetMileStone.Data private knownTimer;

   uint64 [][] private timerMileStone;
    uint64 [] private startTimeStone;

    mapping(uint =>  uint64[2]) private milestone;

    event NewTimePeriod (
        uint64 indexed xtime,
        uint64 indexed ytime
    );
    

        
    constructor(uint64 _timePeriod) {

     
        knownTimer.setPeriod(_timePeriod);
        knownTimer.initMileStone();

        (uint64 _xtime, uint64 ytime) = knownTimer.currentMile();
        setMilestone(_xtime, ytime);
       
     
        
    }


    // set time period using the library   
    function setTimePeriod(uint64 _timePeriod) public   {
        knownTimer.setPeriod(_timePeriod);
    }

    function mileStoneIndexOf(uint i) public 
    view returns(uint64, uint64)
    {
     return (milestone[i][0], milestone[i][1]);
    }
    
    /**
     * @dev Returns all times
    */
    function fetchMileStone() public 
    view returns(uint64[][] memory){
        return timerMileStone;
    }

    /**
     * @dev Set a MileStone
    */
    function setMilestone(uint64 _xtime, uint64 _ytime) 
    private {
        startTimeStone.push(_ytime);
        _timestampId.increment();
        uint256 counter = _timestampId.current();
        milestone[counter][0] = _xtime;
        milestone[counter][1] = _ytime;
        timerMileStone.push([_xtime,_ytime]);
        emit NewTimePeriod(_xtime, _ytime);

    }
    
    /**
     * @dev Returns false if the time is not extandable otherwise increase the MileStone
    */
    function extandMileStone() private 
    returns(bool) {
        // if (isExtandable()) {
        (uint64 _xtime, uint64 ytime) =  knownTimer.currentMile();
        if (knownTimer.isExtandable()){
            startTimeStone.push(ytime);
            knownTimer.increaseMileStone();
            ( _xtime,  ytime) =  knownTimer.currentMile();
            setMilestone(_xtime, ytime);
            emit NewTimePeriod(_xtime, ytime);
            return true;
       }
       return false;
    }
    

    /**
     * @dev Returns the current MileStone 
    */
    function currentMileStone() 
    public view returns( uint64 _x, uint64 _y){
        return knownTimer.currentMile();
    }
    
    /**
     * @dev reset all time 
    */
    function resetMileStone()  public  {
        // require(hasAdminRole()== true);
        knownTimer.resetMileStone();
    }



 

   
    
    /**
    * dev: extend the milestone 
    */
    function extend_() private  {
        bool _x = extandMileStone() ;
        if (_x == true){
            extandMileStone();
        }
    }


 
 
    
    
    
    function maintainClaimTime () private view returns(uint64){
        uint256 counter = _timestampId.current();
        return startTimeStone[counter - 1];
    }

    /**
     *  From the backend claim rewards check if the user has reward-roll and 
     * also check how many nft swaps they did
     *  There is requirement, if the reward-balance is greater than 10,
     * only withdraw 10; however, if it is less than 10, withdraw everything.
     */
    
    

}


/**
 * @title MileStone, CapSequence, or MileSequence
 * @author Anwar (@pcanw)
 * 
 * @dev Mile sequence is a sequence of opportunities for making payment eg.(rewards). It gets collected every period of time.
 * Every time period is like a slice.  
 *  
 * 
 * Readme
 * It is useful library to contain multiple hierarchies timestamp. 
 * 
 * TODO - add a list of the time in the library
 *      - increase/ control time by admin if it is needed in the smart contract
*/


library SetMileStone {
    
    struct Data { 
        uint64 startTime;
        uint64 endTime;
        uint64 period;
    }
    
     /**
     * @dev Sets the period of days 
     */
    function setPeriod(Data storage self, uint64 period) internal {
            self.period = period;
    }
    
     /**
     * @dev Get the period of days 
     */
    function getPeriod(Data storage self) internal view returns (uint64) {
            return self.period;
    }
    
      /**
     * @dev Init MileStone
     * 
     * @notice this should be run at the smart contract constructor and also after reset the milestone
     */
    function initMileStone(Data storage self)
    internal
    {
        require(self.period > 0 && self.startTime < block.timestamp);
        uint64 currentTime = uint64(block.timestamp);
        uint64 reTimer ;
        uint64 period = self.period;
        self.startTime = currentTime + reTimer;
        self.endTime = ((30 days  * self.period) + currentTime) ;
        reTimer = (30 days * period) ;

    }
    
    
    /**
     * @dev Increase MileStone based on the exsiting MileStone in the contract.
    */
    
    function increaseMileStone(Data storage self) 
    internal
         {
        require(isExtandable(self), "Not_Extandable");
        uint64 currentTime = self.endTime;
        uint64 reTimer ;
        self.startTime = currentTime + reTimer;
        self.endTime = ((30 days * self.period) + currentTime + passTimer(self)) ;
        reTimer = (30 days  * self.period) ;
    }
    
    
    
    /**
     * @dev Pass the missing time at the end of the MileStone if there was no extended  
     * it works only if there is no extanded occur or missing to increase the milestone..
     * 
     */
    function passTimer(Data storage self) 
    view private returns(uint64) {
        uint64 timestamp = uint64(block.timestamp);
        if (self.endTime < timestamp){
            uint64 _b = timestamp - self.endTime;
            return _b;
        }else{
            return 0;
        }
    }
    
    
    /**
     * @dev renew the mile timestamp sequence.
     * unused since we continue the milestone of the project. 
     */
    function renewMileStone(Data storage self) 
    internal
         {
        require(isExtandable(self), "UnExtandable");
        uint64 currentTime = self.endTime;
        uint64 reTimer = 0;
        self.startTime = currentTime + reTimer;
        self.endTime = ((30 days * self.period) + currentTime) ;
        reTimer = (30 days  * self.period) ;
    }
    
    /**
     * @dev reset mile sequence .
     * 
     */
    function resetMileStone(Data storage self) internal {
        self.endTime = 0;
        self.startTime = 0;
        self.period = 0;
    }
    
    /**
     * @dev Returns MileStone's start timer and end timer.
     */
    function currentMile(Data storage self)  internal
        view
        returns ( uint64, uint64) {
        return (self.startTime, self.endTime);
    }

    /**
     * @dev Returns the current start timer.
     */

    function currentStartMile(Data storage self) internal
        view
        returns ( uint64) {
        return (self.startTime);
    }

     /**
     * @dev Returns the current end timer.
     */
    function currentEndtMile(Data storage self) internal
        view
        returns ( uint64) {
        return (self.endTime);
    }
    
    
    /**
     * @dev Returns a boolean if current time is in the sequence 
     */
    function isCurrentMile(Data storage self) internal 
    view returns (bool) {
        return self.startTime < block.timestamp && self.endTime > block.timestamp;
    }
    
    /**
     * @dev Returns a boolean if mile sequence is started
    */
    function isMileStarted(Data storage self) internal 
    view returns (bool) {
        return self.startTime > 0;
    }
    
    /**
     * @dev Returns a boolean if one slice of a sequence is ended 
    */
    function isMileExpired(Data storage self) internal 
    view returns (bool) {
            return  self.endTime <= block.timestamp;
    }
    
    /**
     * @dev Returns a boolean if a time sequence can be extanded 
    */
    function isExtandable(Data storage self) internal 
    view returns (bool) {
            require(isMileStarted(self) == true, "No_Start");
            return self.endTime - 15 days <= block.timestamp;
    }

}