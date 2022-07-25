module gov_first::voting_mod {
  use std::signer;
  use std::string;
  use std::vector;
  use gov_first::proposal_mod;
  use gov_first::ballot_box_mod::{Self, BallotBox};
  use gov_first::config_mod;

  struct VotingForum has key {
    ballot_boxes: vector<BallotBox>
  }

  const E_INVALID_VALUE: u64 = 1;

  public fun publish_voting_forum(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, VotingForum { ballot_boxes: vector::empty<BallotBox>() });
  }

  public fun add_proposal(proposer: &signer, title: string::String, content: string::String) acquires VotingForum {
    let proposal = proposal_mod::create_proposal(proposer, title, content);
    let ballot_box = ballot_box_mod::create_ballot_box(proposal);
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    vector::push_back<BallotBox>(&mut voting_forum.ballot_boxes, ballot_box);
  }

  public fun vote_to_yes(proposal_id: u64, number_of_votes: u64) acquires VotingForum {
    vote_internal(proposal_id, number_of_votes, true);
  }
  public fun vote_to_no(proposal_id: u64, number_of_votes: u64) acquires VotingForum {
    vote_internal(proposal_id, number_of_votes, false);
  }
  fun vote_internal(proposal_id: u64, number_of_votes: u64, is_yes: bool) acquires VotingForum {
    assert!(number_of_votes > 0, E_INVALID_VALUE);
    let (idx, finded_proposal_id) = find_proposal(proposal_id);
    assert!(finded_proposal_id > 0, 0);
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    let ballet_box = vector::borrow_mut<BallotBox>(&mut voting_forum.ballot_boxes, idx);
    if (is_yes) {
      ballot_box_mod::vote_to_yes(ballet_box, (number_of_votes as u128));
    } else {
      ballot_box_mod::vote_to_no(ballet_box, (number_of_votes as u128));
    }
  }

  public fun find_proposal(proposal_id: u64): (u64, u64) acquires VotingForum {
    let voting_forum = borrow_global<VotingForum>(config_mod::module_owner());
    let idx = 0;
    let len = vector::length<BallotBox>(&voting_forum.ballot_boxes);
    while (idx < len) {
      let ballot_box = vector::borrow<BallotBox>(&voting_forum.ballot_boxes, idx);
      let uid = ballot_box_mod::uid(ballot_box);
      if (uid == proposal_id) return (idx, uid);
      idx = idx + 1;
    };
    (0, 0)
  }

  #[test(account = @gov_first)]
  fun test_publish_voting_forum(account: &signer) acquires VotingForum {
    publish_voting_forum(account);
    let account_address = signer::address_of(account);
    assert!(exists<VotingForum>(account_address), 0);
    let voting_forum = borrow_global<VotingForum>(account_address);
    assert!(vector::is_empty<BallotBox>(&voting_forum.ballot_boxes), 0);
  }

  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_publish_voting_forum_when_not_module_owner(account: &signer) {
    publish_voting_forum(account);
  }

  #[test(owner = @gov_first, account = @0x1)]
  fun test_add_proposal(owner: &signer, account: &signer) acquires VotingForum {
    // initialize
    publish_voting_forum(owner);
    ballot_box_mod::initialize(owner);

    add_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let owner_address = signer::address_of(owner);
    let voting_forum = borrow_global<VotingForum>(owner_address);
    assert!(vector::length<BallotBox>(&voting_forum.ballot_boxes) == 1, 0);
  }

  #[test(owner = @gov_first, account = @0x1)]
  fun test_find_proposal(owner: &signer, account: &signer) acquires VotingForum {
    // initialize
    publish_voting_forum(owner);
    ballot_box_mod::initialize(owner);

    add_proposal(
      account,
      string::utf8(b"proposal_title_1"),
      string::utf8(b"proposal_content_1"),
    );
    add_proposal(
      account,
      string::utf8(b"proposal_title_2"),
      string::utf8(b"proposal_content_2"),
    );
    add_proposal(
      account,
      string::utf8(b"proposal_title_3"),
      string::utf8(b"proposal_content_3"),
    );
    let (idx, uid) = find_proposal(2);
    assert!(idx == 1, 0);
    assert!(uid == 2, 0);
    let (idx, uid) = find_proposal(3);
    assert!(idx == 2, 0);
    assert!(uid == 3, 0);
    let (idx, uid) = find_proposal(4);
    assert!(idx == 0, 0);
    assert!(uid == 0, 0);
  }

  #[test(owner = @gov_first, account = @0x1)]
  fun test_vote(owner: &signer, account: &signer) acquires VotingForum {
    // initialize
    publish_voting_forum(owner);
    ballot_box_mod::initialize(owner);

    add_proposal(
      account,
      string::utf8(b"proposal_title_1"),
      string::utf8(b"proposal_content_1"),
    );
    add_proposal(
      account,
      string::utf8(b"proposal_title_2"),
      string::utf8(b"proposal_content_2"),
    );

    vote_to_yes(1, 100);
    let voting_forum = borrow_global<VotingForum>(config_mod::module_owner());
    let ballot_box_1 = vector::borrow<BallotBox>(&voting_forum.ballot_boxes, 0);
    assert!(ballot_box_mod::yes_votes(ballot_box_1) == 100, 0);
    assert!(ballot_box_mod::no_votes(ballot_box_1) == 0, 0);
    let ballot_box_2 = vector::borrow<BallotBox>(&voting_forum.ballot_boxes, 1);
    assert!(ballot_box_mod::yes_votes(ballot_box_2) == 0, 0);
    assert!(ballot_box_mod::no_votes(ballot_box_2) == 0, 0);

    vote_to_no(2, 25);
    let voting_forum = borrow_global<VotingForum>(config_mod::module_owner());
    let ballot_box_1 = vector::borrow<BallotBox>(&voting_forum.ballot_boxes, 0);
    assert!(ballot_box_mod::yes_votes(ballot_box_1) == 100, 0);
    assert!(ballot_box_mod::no_votes(ballot_box_1) == 0, 0);
    let ballot_box_2 = vector::borrow<BallotBox>(&voting_forum.ballot_boxes, 1);
    assert!(ballot_box_mod::yes_votes(ballot_box_2) == 0, 0);
    assert!(ballot_box_mod::no_votes(ballot_box_2) == 25, 0);
  }
}