module gov_second::offer_voting_method_mod {
  use std::signer;
  use std::string;
  use aptos_framework::table::{Self, Table};
  use gov_second::config_mod;
  use gov_second::id_counter_mod;
  use gov_second::proposal_meta_mod;
  use gov_second::voting_power_mod;

  struct VotingForum has key {
    proposals: Table<u64, Proposal>
  }

  struct Proposal has store {
    meta: proposal_meta_mod::ProposalMeta,
    up_votes: u64,
    stay_votes: u64,
    down_votes: u64,
    can_use_stay: bool,
  }

  const E_ALREADY_HAVE: u64 = 1;
  const E_PROHIBIT_STAY: u64 = 2;

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::assert_is_module_owner(owner_address);
    assert!(!exists<VotingForum>(owner_address), E_ALREADY_HAVE);
    move_to(owner, VotingForum { proposals: table::new() })
  }

  public fun add_proposal(
    account: &signer,
    title: string::String,
    content: string::String,
    expiration_secs: u64,
    can_use_stay: bool,
  ): u64 acquires VotingForum {
    let account_address = signer::address_of(account);
    let current = 0; // TODO: use timestamp
    let meta = proposal_meta_mod::create_proposal_meta(
      title,
      content,
      account_address,
      expiration_secs,
      current,
      current
    );
    let id = id_counter_mod::generate_id<VotingForum>();
    let proposal = Proposal {
      meta,
      up_votes: 0,
      stay_votes: 0,
      down_votes: 0,
      can_use_stay
    };
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    table::add(&mut voting_forum.proposals, id, proposal);
    id
  }

  public fun get_proposal_info(id: u64): (
    string::String,
    string::String,
    address,
    u64,
    u64,
    u64,
    u64,
    u64,
    u64
  ) acquires VotingForum {
    let voting_forum = borrow_global<VotingForum>(config_mod::module_owner());
    let proposal = table::borrow(&voting_forum.proposals, id);
    let (title, content, proposer, expiration_secs, created_at, updated_at) = proposal_meta_mod::info(&proposal.meta);
    (title, content, proposer, expiration_secs, created_at, updated_at, proposal.up_votes, proposal.stay_votes, proposal.down_votes)
  }

  public fun vote_to_up(account: &signer, id: u64, count: u64) acquires VotingForum {
    vote_internal(account, id, count, true, false);
  }
  public fun vote_to_stay(account: &signer, id: u64, count: u64) acquires VotingForum {
    vote_internal(account, id, count, false, false);
  }
  public fun vote_to_down(account: &signer, id: u64, count: u64) acquires VotingForum {
    vote_internal(account, id, count, false, true);
  }
  fun vote_internal(account: &signer, id: u64, count: u64, is_up: bool, is_down: bool) acquires VotingForum {
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    let proposal = table::borrow_mut(&mut voting_forum.proposals, id);
    let consumed_voting_power = voting_power_mod::use_voting_power(account, count);
    if (is_up) {
      proposal.up_votes = proposal.up_votes + consumed_voting_power;
    } else if (is_down) {
      proposal.down_votes = proposal.down_votes + consumed_voting_power;
    } else {
      assert!(proposal.can_use_stay, E_PROHIBIT_STAY);
      proposal.stay_votes = proposal.stay_votes + consumed_voting_power;
    }
  }

  #[test(owner = @gov_second)]
  fun test_initialize(owner: &signer) {
    initialize(owner);
    let owner_address = signer::address_of(owner);
    assert!(exists<VotingForum>(owner_address), 0);
  }
  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_by_not_owner(owner: &signer) {
    initialize(owner);
  }
  #[test(owner = @gov_second)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_several_times(owner: &signer) {
    initialize(owner);
    initialize(owner);
  }

  #[test(owner = @gov_second, account = @0x1)]
  fun test_add_proposal(owner: &signer, account: &signer) acquires VotingForum {
    initialize(owner);
    id_counter_mod::publish_id_counter<VotingForum>(owner);
    let id = add_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      0,
      true
    );
    let (title, content, proposer, expiration_secs, created_at, updated_at, up_votes, stay_votes, down_votes) = get_proposal_info(id);
    assert!(title == string::utf8(b"proposal_title"), 0);
    assert!(content == string::utf8(b"proposal_content"), 0);
    assert!(proposer == signer::address_of(account), 0);
    assert!(expiration_secs == 0, 0);
    assert!(created_at == 0, 0);
    assert!(updated_at == 0, 0);
    assert!(up_votes == 0, 0);
    assert!(stay_votes == 0, 0);
    assert!(down_votes == 0, 0);
  }

  #[test(owner = @gov_second, account = @0x1)]
  fun test_vote(owner: &signer, account: &signer) acquires VotingForum {
    initialize(owner);
    id_counter_mod::publish_id_counter<VotingForum>(owner);
    let id = add_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      0,
      true
    );

    voting_power_mod::initialize(owner);
    voting_power_mod::publish(account);
    voting_power_mod::increase_voting_power(signer::address_of(account), 2775);

    vote_to_up(account, id, 10);
    vote_to_up(account, id, 15);
    let (_, _, _, _, _, _, up_votes, stay_votes, down_votes) = get_proposal_info(id);
    assert!(up_votes == 25, 0);
    assert!(stay_votes == 0, 0);
    assert!(down_votes == 0, 0);

    vote_to_stay(account, id, 100);
    vote_to_stay(account, id, 150);
    let (_, _, _, _, _, _, up_votes, stay_votes, down_votes) = get_proposal_info(id);
    assert!(up_votes == 25, 0);
    assert!(stay_votes == 250, 0);
    assert!(down_votes == 0, 0);

    vote_to_down(account, id, 1000);
    vote_to_down(account, id, 1500);
    let (_, _, _, _, _, _, up_votes, stay_votes, down_votes) = get_proposal_info(id);
    assert!(up_votes == 25, 0);
    assert!(stay_votes == 250, 0);
    assert!(down_votes == 2500, 0);
  }

  #[test(owner = @gov_second, account = @0x1)]
  #[expected_failure(abort_code = 2)]
  fun test_vote_with_no_stay_flag(owner: &signer, account: &signer) acquires VotingForum {
    initialize(owner);
    id_counter_mod::publish_id_counter<VotingForum>(owner);
    let id = add_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      0,
      false
    );

    voting_power_mod::initialize(owner);
    voting_power_mod::publish(account);
    voting_power_mod::increase_voting_power(signer::address_of(account), 3);

    vote_to_up(account, id, 1);
    vote_to_down(account, id, 1);
    let (_, _, _, _, _, _, up_votes, stay_votes, down_votes) = get_proposal_info(id);
    assert!(up_votes == 1, 0);
    assert!(stay_votes == 0, 0);
    assert!(down_votes == 1, 0);

    vote_to_stay(account, id, 1);
  }
}
