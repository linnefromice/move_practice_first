module TicketTutorial::Tickets {
  use std::Signer;
  use std::Vector;
  use AptosFramework::Coin;
  use AptosFramework::TestCoin::TestCoin;

  #[test_only]
  use AptosFramework::Coin::{
    BurnCapability,
    MintCapability
  };
  #[test_only]
  use AptosFramework::TestCoin as TestCoinModule;

  struct ConcertTicket has key, store {
    seat: vector<u8>,
    ticket_code: vector<u8>,
    price: u64,
  }

  struct Venue has key {
    available_tickets: vector<ConcertTicket>,
    max_seats: u64,
  }

  struct TicketEnvelope has key {
    tickets: vector<ConcertTicket>
  }

  const ENO_VENUE: u64 = 0;
  const ENO_TICKETS: u64 = 1;
  const ENO_ENVELOPE: u64 = 2;
	const EINVALID_TICKET_COUNT: u64 = 3;
	const EINVALID_TICKET: u64 = 4;
	const EINVALID_PRICE: u64 = 5;
	const EMAX_SEATS: u64 = 6;
	const EINVALID_BALANCE: u64 = 7;

  public fun init_venue(venue_owner: &signer, max_seats: u64) {
    move_to<Venue>(venue_owner, Venue { available_tickets: Vector::empty<ConcertTicket>(), max_seats })
  }

  public fun create_ticket(venue_owner: &signer, seat: vector<u8>, ticket_code: vector<u8>, price: u64) acquires Venue {
    let venue_owner_addr = Signer::address_of(venue_owner);
    assert!(exists<Venue>(venue_owner_addr), ENO_VENUE);
    let current_seat_count = available_ticket_count(venue_owner_addr);
    let venue = borrow_global_mut<Venue>(venue_owner_addr);
    assert!(current_seat_count < venue.max_seats, EMAX_SEATS);
    Vector::push_back(&mut venue.available_tickets, ConcertTicket { seat, ticket_code, price })
  }

  public fun available_ticket_count(venue_owner_addr: address): u64 acquires Venue {
    let venue = borrow_global<Venue>(venue_owner_addr);
    Vector::length<ConcertTicket>(&venue.available_tickets)
  }

  fun get_ticket_info(venue_owner_addr: address, seat: vector<u8>): (bool, vector<u8>, u64, u64) acquires Venue {
    assert!(exists<Venue>(venue_owner_addr), ENO_VENUE);
    let venue = borrow_global<Venue>(venue_owner_addr);
    let i = 0;
    let len = Vector::length<ConcertTicket>(&venue.available_tickets);
    while (i < len) {
      let ticket = Vector::borrow<ConcertTicket>(&venue.available_tickets, i);
      if (ticket.seat == seat) return (true, ticket.ticket_code, ticket.price, i);
      i = i + 1;
    };
    return (false, b"", 0, 0)
  }

  public fun get_ticket_price(venue_owner_addr: address, seat: vector<u8>): (bool, u64) acquires Venue {
    let (success, _, price, _) = get_ticket_info(venue_owner_addr, seat);
    assert!(success, EINVALID_TICKET);
    return (success, price)
  }

  public fun purchase_ticket(buyer: &signer, venue_owner_addr: address, seat: vector<u8>) acquires Venue, TicketEnvelope {
    let buyer_addr = Signer::address_of(buyer);
    let (success, _, price, index) = get_ticket_info(venue_owner_addr, seat);
    assert!(success, EINVALID_TICKET);

    let venue = borrow_global_mut<Venue>(venue_owner_addr);
    // Coin::transfer<TestCoin>(buyer, venue_owner_addr, price); // Invalid call to '(AptosFramework=0x1)::Coin::transfer'
    let coin = Coin::withdraw<TestCoin>(buyer, price);
    Coin::deposit(venue_owner_addr, coin);
    let ticket = Vector::remove<ConcertTicket>(&mut venue.available_tickets, index);
    if (!exists<TicketEnvelope>(buyer_addr)) {
      move_to<TicketEnvelope>(buyer, TicketEnvelope { tickets: Vector::empty<ConcertTicket>() });
    };
    let envelope = borrow_global_mut<TicketEnvelope>(buyer_addr);
    Vector::push_back<ConcertTicket>(&mut envelope.tickets, ticket);
  }

  #[test_only]
  struct FakeMoneyCapabilities has key {
    mint_cap: MintCapability<TestCoin>,
    burn_cap: BurnCapability<TestCoin>,
  }

  #[test(venue_owner = @0x11, buyer = @0x12, faucet = @AptosFramework, core_resource = @CoreResources)]
  public(script) fun sender_can_create_ticket(venue_owner: signer, buyer: signer, faucet: signer, core_resource: signer) acquires Venue, TicketEnvelope {
    let venue_owner_addr = Signer::address_of(&venue_owner);

    // initialize the venue
    init_venue(&venue_owner, 3);
    assert!(exists<Venue>(venue_owner_addr), ENO_VENUE);

    // create some tickets
    create_ticket(&venue_owner, b"A24", b"AB43C7F", 15);
		create_ticket(&venue_owner, b"A25", b"AB43CFD", 15);
		create_ticket(&venue_owner, b"A26", b"AB13C7F", 20);

    // verify we have 3 tickets now
    assert!(available_ticket_count(venue_owner_addr) == 3, EINVALID_TICKET_COUNT);

    // verify seat and price
    let (success, price) = get_ticket_price(venue_owner_addr, b"A24");
    assert!(success, EINVALID_TICKET);
    assert!(price == 15, EINVALID_PRICE);

    // initialize & fund account to buy tickets
    let (mint_cap, burn_cap) = TestCoinModule::initialize(&faucet, &core_resource);
    move_to(&faucet, FakeMoneyCapabilities { mint_cap, burn_cap });
    Coin::register_internal<TestCoin>(&venue_owner);
    Coin::register_internal<TestCoin>(&buyer);
    let amount = 100;
    let buyer_addr = Signer::address_of(&buyer);
    let coin_for_buyer = Coin::withdraw<TestCoin>(&core_resource, amount);
    // let coin_for_buyer = Coin::mint<TestCoin>(amount, &mint_cap); // <- Invalid return
    Coin::deposit<TestCoin>(buyer_addr, coin_for_buyer);
    assert!(Coin::balance<TestCoin>(buyer_addr) == 100, EINVALID_BALANCE);

    // buy a first ticket and confirm account balance changes
    purchase_ticket(&buyer, venue_owner_addr, b"A24");
    assert!(exists<TicketEnvelope>(buyer_addr), ENO_ENVELOPE);
    assert!(Coin::balance<TestCoin>(buyer_addr) == 85, EINVALID_BALANCE);
    assert!(Coin::balance<TestCoin>(venue_owner_addr) == 15, EINVALID_BALANCE);
    assert!(available_ticket_count(venue_owner_addr) == 2, EINVALID_TICKET_COUNT);
    let envelope = borrow_global<TicketEnvelope>(buyer_addr);
    assert!(Vector::length<ConcertTicket>(&envelope.tickets) == 1, EINVALID_TICKET_COUNT);

    // buy a second ticket and confirm account balance changes
    purchase_ticket(&buyer, venue_owner_addr, b"A26");
    assert!(exists<TicketEnvelope>(buyer_addr), ENO_ENVELOPE);
    assert!(Coin::balance<TestCoin>(buyer_addr) == 65, EINVALID_BALANCE);
    assert!(Coin::balance<TestCoin>(venue_owner_addr) == 35, EINVALID_BALANCE);
    assert!(available_ticket_count(venue_owner_addr) == 1, EINVALID_TICKET_COUNT);
    let envelope_2nd = borrow_global<TicketEnvelope>(buyer_addr);
    assert!(Vector::length<ConcertTicket>(&envelope_2nd.tickets) == 2, EINVALID_TICKET_COUNT);
  }
}