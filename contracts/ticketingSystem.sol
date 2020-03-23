pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract ticketingSystem {

    uint public totalOfArtists = 0;

    struct artist {
        uint id;
        bytes32 name;
        uint artistCategory;
        uint totalTicketSold;
        address owner;
    }
    mapping( uint => artist ) public artistsRegister;

    event newArtistCreated(uint);

    function createArtist(bytes32 _name, uint _categroy) public {
        artist memory newArtist;
        totalOfArtists += 1;
        newArtist.id = totalOfArtists;
        newArtist.name = _name;
        newArtist.artistCategory = _categroy;
        newArtist.owner = msg.sender;
        artistsRegister[totalOfArtists] = newArtist;
        emit newArtistCreated(newArtist.id);
    }

    // event artistRegistered(uint);

    // function artistsRegister(uint id) public returns (artist memory) {
    //     emit artistRegistered(id);
    //     return artistList[id];
    // }

    modifier onlyArtistOwner(uint _id){
        require(msg.sender == artistsRegister[_id].owner, "You are not the owner of the artist");
        _;
    }
    event artistModified(uint);

    function modifyArtist(uint _id, bytes32 _name, uint _categroy, address payable _address) public onlyArtistOwner(_id) {
        artistsRegister[_id].name = _name;
        artistsRegister[_id].artistCategory = _categroy;
        artistsRegister[_id].owner = _address;
        emit artistModified(_id);
    }

    struct venue{
        uint id;
        bytes32 name;
        uint capacity;
        uint standardComission;
        address payable owner;
    }

    uint public totalOfVenues = 0;

    mapping( uint => venue ) public venuesRegister;
    event venueCreated(uint);

    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public {
        venue memory newVenue;
        totalOfVenues++;
        newVenue.id = totalOfVenues;
        newVenue.name = _name;
        newVenue.capacity = _capacity;
        newVenue.standardComission = _standardComission;
        newVenue.owner = msg.sender;
        venuesRegister[newVenue.id] = newVenue;
        emit venueCreated(newVenue.id);
    }

    modifier onlyVenueOwner(uint _id){
        require(msg.sender == venuesRegister[_id].owner, "You are not the owner of the venue.");
        _;
    }

    event venueModified(uint);

    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner)
        public onlyVenueOwner(_venueId){
        venuesRegister[_venueId].name = _name;
        venuesRegister[_venueId].capacity = _capacity;
        venuesRegister[_venueId].standardComission = _standardComission;
        venuesRegister[_venueId].owner = _newOwner;
        emit venueModified(_venueId);
    }

    struct concert{
        uint concertId;
        uint artistId;
        uint venueId;
        uint concertDate;
        uint ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
        uint totalSoldTicket;
        uint totalMoneyCollected;
    }
    mapping( uint => concert ) public concertsRegister;
    uint public totalOfConcerts = 0;

    event concertCreated(uint);

    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public {
        totalOfConcerts++;
        concert memory newConcert;
        newConcert.concertId = totalOfConcerts;
        newConcert.artistId = _artistId;
        newConcert.venueId = _venueId;
        newConcert.concertDate = _concertDate;
        newConcert.ticketPrice = _ticketPrice;
        if (msg.sender == artistsRegister[_artistId].owner){
            newConcert.validatedByArtist = true;
        }
        else{
            newConcert.validatedByArtist = false;
        }
        newConcert.validatedByVenue = false;
        concertsRegister[newConcert.concertId] = newConcert;
        emit concertCreated(totalOfConcerts);
    }

    event concertValidatedByArtist(uint);
    event concertValidatedByVenue(uint);

    function validateConcert(uint _concertId) public {
        if( msg.sender == artistsRegister[concertsRegister[_concertId].artistId].owner){
            concertsRegister[_concertId].validatedByArtist = true;
            emit concertValidatedByArtist(_concertId);
        }
        else if (msg.sender == venuesRegister[concertsRegister[_concertId].venueId].owner){
            concertsRegister[_concertId].validatedByVenue = true;
            emit concertValidatedByVenue(_concertId);
        }
    }


    struct ticket{
        uint ticketId; //don't initialize concertId = 0 !
        uint concertId;
        address owner;
        uint amountPaid;
        bool isAvailable;
        bool isAvailableForSale;
    }
    uint public totalTicket = 0;
    mapping( uint => ticket ) public ticketsRegister;

    event newTicketEmitted(uint);

    function emitTicket(uint _concertId, address payable _ticketOwner) public onlyArtistOwner(concertsRegister[_concertId].artistId) {
        ticket memory newTicket;
        totalTicket++;
        newTicket.ticketId = totalTicket;
        newTicket.concertId = _concertId;
        newTicket.owner = _ticketOwner;
        newTicket.isAvailable = true;
        newTicket.isAvailableForSale = true;
        ticketsRegister[totalTicket] = newTicket;
        concertsRegister[_concertId].totalSoldTicket += 1;
        emit newTicketEmitted(newTicket.ticketId);
    }

    modifier onlyTicketOwner(uint _ticketId){
        require(msg.sender == ticketsRegister[_ticketId].owner,"Error, you are not the owner of the ticket.");
        _;
    }
    modifier onlyTheDayOf(uint _ticketId){
        require(concertsRegister[ticketsRegister[_ticketId].concertId].concertDate <= now + 1 days,
        "Error, you can't use the ticket before the concert date.");
        _;
    }
    modifier onlyIfValidatedByVenue(uint _ticketId){
        require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true, "Error, the venue as not validated the event.");
        _;
    }

    event ticketUsed(uint);

    function useTicket(uint _ticketId) public
        onlyTicketOwner(_ticketId)
        onlyTheDayOf(_ticketId)
        onlyIfValidatedByVenue(_ticketId){
            ticketsRegister[_ticketId].isAvailable = false;
            ticketsRegister[_ticketId].owner = address(0);
            emit ticketUsed(_ticketId);
    }

    event buyTicketSucceed(uint);

    function buyTicket(uint _concertId) public payable{
        require(msg.value == concertsRegister[_concertId].ticketPrice,
        "Error, the price sent is not enough. Please check the concert price asked.");
        ticket memory newTicket;
        totalTicket++;
        newTicket.ticketId = totalTicket;
        newTicket.concertId = _concertId;
        newTicket.owner = msg.sender;
        newTicket.isAvailable = true;
        newTicket.isAvailableForSale = false;
        newTicket.amountPaid = msg.value;
        concertsRegister[_concertId].totalMoneyCollected += msg.value;
        ticketsRegister[totalTicket] = newTicket;
        concertsRegister[_concertId].totalSoldTicket += 1;
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold += 1;
        emit buyTicketSucceed(_concertId);
    }

    event ticketTransfered(uint,address);

    function transferTicket(uint _ticketId, address payable _newOwner) public onlyTicketOwner(_ticketId){
        ticketsRegister[_ticketId].owner = _newOwner;
        emit ticketTransfered(_ticketId,_newOwner);
    }

    event concertCashOut(uint);

    modifier onlyConcertOwner(uint id) {
        require(msg.sender == artistsRegister[concertsRegister[id].artistId].owner,"You are not the concert owner.");
        _;
    }

    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public onlyConcertOwner(_concertId) {
        require(concertsRegister[_concertId].concertDate <= now,
        "Error, you can't use the ticket before the concert date.");
        //computation
        uint totalTicketSale = concertsRegister[_concertId].ticketPrice * concertsRegister[_concertId].totalSoldTicket;
        uint venueShare = totalTicketSale * venuesRegister[concertsRegister[_concertId].venueId].standardComission / 10000;
        uint artistShare = totalTicketSale - venueShare;
        _cashOutAddress.transfer(artistShare);
        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueShare);
        emit concertCashOut(_concertId);
    }

    event ticketOfferedForSale(uint);

    function offerTicketForSale(uint _ticketId, uint _salePrice) public onlyTicketOwner(_ticketId){
        require(concertsRegister[ticketsRegister[_ticketId].concertId].ticketPrice >= _salePrice,
        "Error, you can't sale a ticket for more than you paid for it");
        concertsRegister[ticketsRegister[_ticketId].concertId].ticketPrice = _salePrice;
        ticketsRegister[_ticketId].isAvailable = true;
        ticketsRegister[_ticketId].isAvailableForSale = true;
        emit ticketOfferedForSale(_ticketId);
    }

    event ticketBoughtSecondHand(uint,address);

    function buySecondHandTicket(uint _ticketId) public payable {
        require(msg.value >= concertsRegister[ticketsRegister[_ticketId].concertId].ticketPrice,
        "Error, the value sent is not enough.");
        require(ticketsRegister[_ticketId].isAvailable == true,
        "Error, the ticket isn't available anymore.");
        ticketsRegister[_ticketId].owner = msg.sender;
        ticketsRegister[_ticketId].isAvailableForSale = false;
        emit ticketBoughtSecondHand(_ticketId,msg.sender);
    }


}