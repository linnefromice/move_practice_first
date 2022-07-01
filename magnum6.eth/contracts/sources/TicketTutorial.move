module TicketTutorial::Tickets {
  use std::Signer;
  use std::Vector;

  struct ConcertTicket has key, store {
    seat: vector<u8>,
    ticket_code: vector<u8>,
  }

  struct Venue has key {
    available_tickets: vector<ConcertTicket>,
    max_seats: u64,
  }

  const ENO_VENUE: u64 = 0;
  const ENO_TICKETS: u64 = 1;
  const ENO_ENVELOPE: u64 = 2;
	const EINVALID_TICKET_COUNT: u64 = 3;
	const EINVALID_TICKET: u64 = 4;
	const EINVALID_PRICE: u64 = 5;
	const EMAX_SEATS: u64 = 6;
	const EINVALID_BALANCE: u64 = 7;

  public fun create_ticket(recipient: &signer, seat: vector<u8>, ticket_code: vector<u8>) {
    move_to<ConcertTicket>(recipient, ConcertTicket { seat, ticket_code })
  }

  public fun init_venue(venue_owner: &signer, max_seats: u64) {
    move_to<Venue>(venue_owner, Venue { available_tickets: Vector::empty<ConcertTicket>(), max_seats })
  }

  #[test(venue_owner = @0x1)]
  public(script) fun sender_can_create_ticket(venue_owner: signer) {
    let venue_owner_addr = Signer::address_of(&venue_owner);
    init_venue(&venue_owner, 3);
    assert!(exists<Venue>(venue_owner_addr), ENO_VENUE);
  }
}