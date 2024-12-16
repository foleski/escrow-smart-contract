// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

contract Escrow {
    mapping (uint => address[2]) dealParticipants; // id => [seller, buyer]
    mapping (uint => uint) dealAmounts; // id => amount
    mapping (uint => bool) status; // id => activity status
    mapping (uint => bool) deposits; // id => deposit status
    uint id;

    event dealCreated(uint indexed id, address seller, address buyer, uint amount);
    event deposit(uint indexed id, address seller, address buyer, uint amount);
    event dealCompleted(uint indexed id, address seller, address buyer, uint amount);
    event dealCanceled(uint indexed id, address seller, address buyer, uint amount);

    function createDeal(address seller, address buyer, uint amount) public {
        dealParticipants[id] = [seller, buyer];
        dealAmounts[id] = amount;
        status[id] = true;

        emit dealCreated(id, dealParticipants[id][0], dealParticipants[id][1], dealAmounts[id]);
        id++;
    }

    function depositToEscrow(uint id) public payable {
        require(status[id], "Deal is not active. The funds will be returned to your wallet.");
        require(msg.sender == dealParticipants[id][1], "You are not a buyer in this deal. The funds will be returned to your wallet.");
        require(msg.value == dealAmounts[id], "The deal amount is more than what you sent! The funds will be returned to your wallet.");

        deposits[id] = true;
        emit deposit(id, dealParticipants[id][0], dealParticipants[id][1], dealAmounts[id]);
    }

    function confirm(uint id) public {
        require(status[id], "Deal is not active.");
        require(msg.sender == dealParticipants[id][1], "You are no a buyer in this deal. You can't confirm it.");
        require(deposits[id]);

        payable(dealParticipants[id][0]).transfer(dealAmounts[id]);
        emit dealCompleted(id, dealParticipants[id][0], dealParticipants[id][1], dealAmounts[id]);
        status[id] = false;
    }

    function cancel(uint id) public {
        require(status[id], "Deal is not active.");
        require(msg.sender == dealParticipants[id][0] || msg.sender == dealParticipants[id][1], "You are not participant of this deal.");

        if (deposits[id]) {
            payable(dealParticipants[id][1]).transfer(dealAmounts[id]);
        }
        
        emit dealCanceled(id, dealParticipants[id][0], dealParticipants[id][1], dealAmounts[id]);
        status[id] = false;
    }
}