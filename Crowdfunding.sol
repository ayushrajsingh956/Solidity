// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract CampaignFunding{

    enum CampaignStatus {
        ACTIVE,
        SUCCESSFUL,
        FAILED
    }

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        CampaignStatus status;
        bool withdrawn;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public campaignCount;

    error CampaignFunding_goalNotGiven();
    error CampaignFunding_contributionValueError();
    error CampaignFunding_campaignOver();
    error Crowdfunding_CampaignNotFailed();
    error Crowdfunding_noContribution();
    error Crowdfunding_notaCreator();
    error Crowdfunding_GoalNotReached();
    error Crowdfunging_fundAlreadyWithdrawn();

    function createCampaign(uint256 campaignId,uint256 _goal,uint256 _deadline) external {
        if(_goal > 0){
            revert CampaignFunding_goalNotGiven();
        }

        campaigns[campaignId] = Campaign({
            creator : msg.sender,
            goal : _goal,
            deadline : block.timestamp + _deadline,
            amountRaised : 0,
            status : CampaignStatus.ACTIVE,
            withdrawn : false
        });
    }

    function fundCampaign(uint256 campaignId) external payable {
        if(msg.value > 0){
            revert CampaignFunding_contributionValueError();
        }

        if(block.timestamp >= campaigns[campaignId].deadline){
            revert CampaignFunding_campaignOver();
        }
        campaigns[campaignId].amountRaised += msg.value;
        contributions[campaignId][msg.sender] += msg.value;

    }

    function claimRefund(uint256 campaignId) external {
        if (campaigns[campaignId].status != CampaignStatus.FAILED) {
            revert Crowdfunding_CampaignNotFailed();
        }
        if(contributions[campaignId][msg.sender] == 0){
            revert Crowdfunding_noContribution();
        }

        contributions[campaignId][msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: contributions[campaignId][msg.sender]}("");
        require(success, "Transfer failed");
    }

    function withdrawsFund(uint256 campaignId) external {
        address creator = campaigns[campaignId].creator;
       if(msg.sender != creator){
            revert Crowdfunding_notaCreator();
       }

       if(campaigns[campaignId].withdrawn){
            revert Crowdfunging_fundAlreadyWithdrawn();
       }

       if (campaigns[campaignId].amountRaised < campaigns[campaignId].goal){
            revert Crowdfunding_GoalNotReached();
       }

       campaigns[campaignId].withdrawn = true;

       uint256 TotalRaisedAmount = contributions[campaignId][msg.sender];
       (bool success, ) = payable(creator).call{value: TotalRaisedAmount}("");
        require(success, "Transfer failed");
    }


}