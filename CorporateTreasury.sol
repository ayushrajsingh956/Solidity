// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract CorporateTreasury{
    enum Continent{
        None,
        NorthAmerica,
        Europe,
        Asia,
        Oceania,
        SouthAmerica,
        Africa
    }
    enum AssetClass{
        Equity, 
        FixedIncome, 
        Crypto, 
        RealEstate
    }

    struct Investment{
        uint256 id;
        address investor;
        string assetName;
        uint256 principal;
        uint256 timestamp;
        Continent continent;
        AssetClass assetClass;
    }

    mapping(uint256 => Investment) public ledger;
    mapping(uint256 => bool) public idUsed;

    uint256 public totalInvestmentsCount;
    address public owner;
    uint256 totalSecondperDay = 86_400;

    error CorporateTreasury_NotAuthorized();
    modifier onlyOwner(){
        //require(msg.sender != owner,'Not Authorized');  ====>   "So require use more gases that's why usally we don't use it."
        if(msg.sender != owner){
            revert CorporateTreasury_NotAuthorized();
        }
        _;
    }

    event InvestmentRecorded(uint256 id,address investor,string assetName, uint principal,Continent continent);
    error CorporateTreasury_InvalidAmount();
    error CorporateTreasury_Select_Continent();
    error CorporateTreasury_ID_Exists();
    function addInvestment(uint256 _id, string memory _assetName, Continent _continent, AssetClass _assetClass) external payable {
        if(msg.value == 0){
            revert CorporateTreasury_InvalidAmount();
        }
        if(_continent == Continent.None){
            revert CorporateTreasury_InvalidAmount();
        }
        if(idUsed[_id] == false){
            revert CorporateTreasury_ID_Exists();
        }
        ledger[_id] = Investment({
            id : _id,
            investor : msg.sender,
            assetName : _assetName,
            principal : msg.value,
            timestamp : block.timestamp,
            continent : _continent,
            assetClass : _assetClass 
        });

        idUsed[_id] = true;
        totalInvestmentsCount++;
        emit InvestmentRecorded(_id, msg.sender, _assetName, msg.value, _continent);
    }

    error CorporateTreasury_Investment_does_not_exist();
    function getDaysUnderManagement(uint256 _id) public view returns (uint256 daysUnderMgmt){
        if(idUsed[_id] == false){
            revert CorporateTreasury_Investment_does_not_exist();
        }
        daysUnderMgmt = (block.timestamp - ledger[_id].timestamp)/totalSecondperDay;
        return daysUnderMgmt;
    }

    function calculateYield(uint256 _id) public view returns (uint256 accruedYield){
        if(idUsed[_id] == false){
            revert CorporateTreasury_Investment_does_not_exist();
        }
        uint256 Days_Active = getDaysUnderManagement(_id);
        uint8 perDay_Rate = 5;
        if(Days_Active == 0){
            accruedYield = 0;
            return accruedYield;
        }
        accruedYield = (ledger[_id].principal * Days_Active * perDay_Rate)/36500;
        return accruedYield;
    }

    function getInvestmentSummary(uint256 _id) external view returns ( address investor, uint256 principal, Continent continent ){
        if(idUsed[_id] == false){
            revert CorporateTreasury_Investment_does_not_exist();
        }
        return (ledger[_id].investor,ledger[_id].principal,ledger[_id].continent);
    }

}