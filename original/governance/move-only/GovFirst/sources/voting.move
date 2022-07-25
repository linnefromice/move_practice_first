module gov_first::voting {
  use std::signer;
  use std::vector;
  use gov_first::ballot_box_mod::BallotBox;
  use gov_first::config_mod;

  struct VotingForum has key {
    ballet_boxes: vector<BallotBox>
  }

  public fun publish_voting_forum(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, VotingForum { ballet_boxes: vector::empty<BallotBox>() });
  }

  #[test(account = @gov_first)]
  fun test_publish_voting_forum(account: &signer) acquires VotingForum {
    publish_voting_forum(account);
    let account_address = signer::address_of(account);
    assert!(exists<VotingForum>(account_address), 0);
    let voting_forum = borrow_global<VotingForum>(account_address);
    assert!(vector::is_empty<BallotBox>(&voting_forum.ballet_boxes), 0);
  }
}