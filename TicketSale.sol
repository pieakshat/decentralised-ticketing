// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract TicketSale {
    address payable public owner; 
    uint public price; 
    uint public totalTickets; 
    mapping (address => uint) public purchases; 

    constructor(uint  _price, uint _totalTickets) {
        owner = payable (msg.sender); 
        price = _price; 
        totalTickets = _totalTickets; 
    } 

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner has the access"); 
        _; 
    }

    event ticketsSold(address buyer, uint PricePaid, uint ticketsBought);
    event priceChanged(uint newPrice);  
    event resaleInitiated(address seller, uint price, uint NoOfTickets); 
    event ticketResold(address buyer, address seller, uint ticketsSold, uint priceOfResale); 

    function changePrice(uint _newPrice) public onlyOwner() {
        price = _newPrice; 
        emit priceChanged(_newPrice);
    }

    function changeTicketSupply(uint _num, bool add) public onlyOwner() {
        if(add) {
            totalTickets += _num; 
        } else {
            totalTickets -= _num; 
        }
    }

    function priceToPay(uint _ticketsToBuy) public view returns(uint) {
        return price * _ticketsToBuy; 
    }

    function buyTicket(uint _ticketsToBuy) public payable {
        require(_ticketsToBuy <= 10, 'a maximum of only 10 tickets can be bought');
        require(msg.value == priceToPay(_ticketsToBuy), "price not accurate check price to pay"); 
        owner.transfer(msg.value); // transfers the amount paid to owner's account
        totalTickets -= _ticketsToBuy; 
        purchases[msg.sender] += _ticketsToBuy; 
        emit ticketsSold(msg.sender, msg.value, _ticketsToBuy);
    }

    struct reseller {
        address resellerAddress; 
        uint price;
        uint tickets; 
    }

    reseller[] public resellers; 
    mapping (address => uint) ticketsOnResale; // keeps tracks of how many tickets a seller wants to sell
    mapping (address => uint) resalePrice;  // keeps track of at what price the seller is selling a ticket 

    function initiateResale(uint _resalePrice, uint _ticketsToSell) public { // anyone holding the tickets can initialize resale
        require (purchases[msg.sender] >= _ticketsToSell, "you don't have sufficient tickets to sell"); 
        ticketsOnResale[msg.sender] = _ticketsToSell; 
        resalePrice[msg.sender] = _resalePrice; 
        emit resaleInitiated(msg.sender, _resalePrice, _ticketsToSell);
    }

    function checkResaleAmount(address _seller, uint _ticketsToBuy) public view returns(uint) {
        require (_ticketsToBuy <= ticketsOnResale[_seller], "seller is not selling these many tickets"); 
       uint resaleprice = resalePrice[_seller];  // get the price seller is selling at 
        return resaleprice * _ticketsToBuy;  
    }

    function buyResaleTicket(address _seller, uint _ticketsToBuy) public payable {
        uint amount = checkResaleAmount(_seller, _ticketsToBuy);     // get the price seller is selling at 
        require(msg.value == amount, "value not accurate check resale amount"); 
        purchases[msg.sender] += _ticketsToBuy; // add tickets to the account
        purchases[_seller] -= _ticketsToBuy; // remove tickets from the account 
        ticketsOnResale[_seller] -= _ticketsToBuy;
        if (ticketsOnResale[_seller] == 0) {        // if seller has 0 tickets to sell price 0 
            resalePrice[_seller] = 0 ; 
        }
        emit ticketResold(msg.sender, _seller, _ticketsToBuy, amount);
    }

}