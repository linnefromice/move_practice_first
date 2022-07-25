module gov_first::voting {
  use std::signer;
  use std::string;
  use std::vector;
  use gov_first::proposal_mod;
  use gov_first::ballot_box_mod::{Self, BallotBox};
  use gov_first::config_mod;

  struct VotingForum has key {
    ballet_boxes: vector<BallotBox>
  }

  public fun publish_voting_forum(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, VotingForum { ballet_boxes: vector::empty<BallotBox>() });
  }

  public fun add_proposal(proposer: &signer, title: string::String, content: string::String) acquires VotingForum {
    let proposal = proposal_mod::create_proposal(proposer, title, content);
    let ballot_box = ballot_box_mod::create_ballot_box(proposal);
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    vector::push_back<BallotBox>(&mut voting_forum.ballet_boxes, ballot_box);
  }

  public fun find_proposal(proposal_id: u64): (u64, u64) acquires VotingForum {
    let voting_forum = borrow_global<VotingForum>(config_mod::module_owner());
    let idx = 0;
    let len = vector::length<BallotBox>(&voting_forum.ballet_boxes);
    while (idx < len) {
      let ballot_box = vector::borrow<BallotBox>(&voting_forum.ballet_boxes, idx);
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
    assert!(vector::is_empty<BallotBox>(&voting_forum.ballet_boxes), 0);
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
    assert!(vector::length<BallotBox>(&voting_forum.ballet_boxes) == 1, 0);
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
}
