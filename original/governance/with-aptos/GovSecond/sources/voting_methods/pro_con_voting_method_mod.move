module gov_second::pro_con_voting_method_mod {
  use std::signer;
  use std::string;
  use aptos_framework::table::{Self, Table};
  use gov_second::config_mod;
  use gov_second::id_counter_mod;
  use gov_second::proposal_meta_mod;

  struct VotingForum has key {
    proposals: Table<u64, Proposal>
  }

  struct Proposal has store {
    meta: proposal_meta_mod::ProposalMeta,
    yes_votes: u64,
    no_votes: u64,
  }

  const E_ALREADY_HAVE: u64 = 1;

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
    expiration_secs: u64
  ) acquires VotingForum {
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
      yes_votes: 0,
      no_votes: 0
    };
    let voting_forum = borrow_global_mut<VotingForum>(config_mod::module_owner());
    table::add(&mut voting_forum.proposals, id, proposal);
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
    add_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      0,
    );
  }
}