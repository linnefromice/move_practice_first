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
}