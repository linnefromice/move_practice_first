module gov_first::voting_mod {
  use std::signer;
  use std::string;
  use std::event::{Self, EventHandle};
  use aptos_framework::table::{Self, Table};
  use gov_first::proposal_mod;
  use gov_first::ballot_box_mod::{Self, BallotBox};
  use gov_first::config_mod;

  struct ProposeEvent has drop, store {
    uid: u64,
    proposer: address,
  }

  struct BallotBoxKey has copy, drop, store {
    uid: u64,
    proposer: address
  }

  struct VotingForum has key {
    ballot_boxes: Table<BallotBoxKey, BallotBox>,
    propose_events: EventHandle<ProposeEvent>,
  }

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, VotingForum {
      ballot_boxes: table::new(),
      propose_events: event::new_event_handle<ProposeEvent>(owner)
    })
  }

  public fun propose(
    proposer: &signer,
    title: string::String,
    content: string::String,
    expiration_secs: u64
  ): BallotBoxKey acquires VotingForum {
    let proposal = proposal_mod::create_proposal(
      proposer,
      title,
      content
    );
    let ballot_box = ballot_box_mod::create_ballot_box(proposal, expiration_secs);
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    let key = BallotBoxKey {
      uid: ballot_box_mod::uid(&ballot_box),
      proposer: signer::address_of(proposer),
    };
    table::add(&mut voting_forum.ballot_boxes, key, ballot_box);
    event::emit_event<ProposeEvent>(
      &mut voting_forum.propose_events,
      ProposeEvent {
        uid: key.uid,
        proposer: key.proposer,
      }
    );
    key
  }

  #[test_only]
  use std::timestamp;

  #[test(owner = @gov_first)]
  fun test_initialize(owner: &signer) {
    initialize(owner);
    let owner_address = signer::address_of(owner);
    assert!(exists<VotingForum>(owner_address), 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_not_module_owner(account: &signer) {
    initialize(account);
  }

  #[test(framework = @AptosFramework, owner = @gov_first, account = @0x1)]
  fun test_propose(framework: &signer, owner: &signer, account: &signer) acquires VotingForum {
    let per_microseconds = 1000 * 1000;
    let day = 24 * 60 * 60;

    timestamp::set_time_has_started_for_testing(framework);
    ballot_box_mod::initialize(owner);
    initialize(owner);
    let key = propose(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      1 * day * per_microseconds
    );
    let owner_address = signer::address_of(owner);
    let voting_forum = borrow_global<VotingForum>(owner_address);
    assert!(table::length<BallotBoxKey, BallotBox>(&voting_forum.ballot_boxes) == 1, 0);
    let ballot_box = table::borrow<BallotBoxKey, BallotBox>(&voting_forum.ballot_boxes, key);
    assert!(ballot_box_mod::uid(ballot_box) == 1, 0);
  }
}