// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract EventTicketingPlatform {
    //enums are the collection of members or pre-define constants.
    enum EventType {
        None,
        Conference,
        Workshop,
        Hackathon,
        Meetup,
        Webinar,
        Summit
    }

    enum TicketTier {
        Standard,
        Premium,
        VIP
    }

    struct Ticket {
        uint256 ticketId;
        address buyer;
        string eventName;
        uint256 purchaseAmount;
        uint256 purchaseTimestamp;
        uint256 eventTimestamp;
        EventType eventType;
        TicketTier ticketTier;
    }

    event TicketPurchased(
        uint256 indexed ticketId,
        address indexed buyer,
        string eventName,
        uint256 amountPaid,
        EventType eventType
    );

    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => bool) public ticketUsed;
    uint256 public totalTicketsSold;
    address public owner;
    uint256 SecondsinaDay = 86400;

    constructor(){
        owner = msg.sender;
    }

    error EventTicketingPlatform_NotAuthorized();
    error EventTicketingPlatform_InvalidAmmount();
    error EventTicketingPlatform_SelectEventType();
    error EventTicketingPlatform_Invalid_Event_Date(uint256 Event_Date);
    error EventTicketingPlatform_Ticket_Exists(uint256 knownTickect);
    error EventTicketingPlatform_Ticket_does_not_exist(uint256 Tickect_Id);

    modifier onlyOwner(){
        if(owner != msg.sender){
            revert EventTicketingPlatform_NotAuthorized();
        }
        _;
    }

    function PurchaseTicket (uint256 _ticketId,string calldata _eventName,uint256 _eventTimestamp,EventType _eventType,TicketTier _ticketTier) external payable{
        if (msg.value == 0){
            revert EventTicketingPlatform_InvalidAmmount();
        }
        if (EventType.None == _eventType){
            revert EventTicketingPlatform_SelectEventType();
        }
        if(_eventTimestamp <= block.timestamp){
            revert EventTicketingPlatform_Invalid_Event_Date(_eventTimestamp);
        }
        if (ticketUsed[_ticketId]){
            revert EventTicketingPlatform_Ticket_Exists(_ticketId);
        }
        tickets[_ticketId] = Ticket({
            ticketId: _ticketId,
            buyer: msg.sender,
            eventName: _eventName,
            purchaseAmount:msg.value,
            purchaseTimestamp: block.timestamp,
            eventTimestamp:_eventTimestamp,
            eventType: _eventType,
            ticketTier: _ticketTier
        });

        ticketUsed[_ticketId] = true;

        totalTicketsSold++;

        emit TicketPurchased(
            _ticketId,
            msg.sender,
            _eventName,
            msg.value,
            _eventType
        );
    }

    function getDaysUntilEvent(uint256 _ticketId) public view returns (uint256 daysRemaining){
        if(tickets[_ticketId].ticketId == _ticketId){
            revert EventTicketingPlatform_Ticket_does_not_exist(_ticketId);
        }

        daysRemaining = (tickets[_ticketId].eventTimestamp - block.timestamp)/SecondsinaDay;

        return daysRemaining;
    }

    function calculateRefundAmount(uint256 _ticketId) public view returns (uint256 refundAmount){
         if(tickets[_ticketId].ticketId == _ticketId){
            revert EventTicketingPlatform_Ticket_does_not_exist(_ticketId);
        }

        uint256 days_remaining = getDaysUntilEvent(_ticketId);

        if (days_remaining >= 30){
            refundAmount = tickets[_ticketId].purchaseAmount * 80 / 100;
        }
        else if (days_remaining < 30 && days_remaining >= 15){
            refundAmount = tickets[_ticketId].purchaseAmount * 50 / 100;
        }
        else if (days_remaining < 15 && days_remaining >= 7){
            refundAmount = tickets[_ticketId].purchaseAmount * 25 / 100;
        }
        else if (days_remaining < 7){
            refundAmount = 0;
        }
        
        return refundAmount;
    }

    function getTicketSummary(uint256 _ticketId)external view returns (address buyer,uint256 purchaseAmount,TicketTier tier){
        if(tickets[_ticketId].ticketId == _ticketId){
            revert EventTicketingPlatform_Ticket_does_not_exist(_ticketId);
        }
        buyer = tickets[_ticketId].buyer;
        purchaseAmount = tickets[_ticketId].purchaseAmount;
        tier = tickets[_ticketId].ticketTier;

        return(buyer,purchaseAmount,tier);
    }

}