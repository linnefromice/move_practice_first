module gov_first::pro_con_voting_method_mod {
  use std::string;
  use gov_first::voting_mod;

  struct ProConVotingMethod has store {
    yes_votes: u64,
    no_votes: u64,
  }

  public fun propose(
    proposer: &signer,
    title: string::String,
    content: string::String,
    expiration_secs: u64
  ) {
    let methods = ProConVotingMethod { yes_votes: 0, no_votes: 0 };
    voting_mod::propose<ProConVotingMethod>(
      proposer,
      title,
      content,
      methods,
      expiration_secs,
    );
  }

  #[test_only]
  use std::signer;
  #[test_only]
  use std::timestamp;
  #[test_only]
  use gov_first::ballot_box_mod;
  #[test_only]
  fun initialize_for_test(framework: &signer, owner: &signer) {
    timestamp::set_time_has_started_for_testing(framework);
    ballot_box_mod::initialize(owner);
    voting_mod::initialize<ProConVotingMethod>(owner);
  }
  #[test(framework = @AptosFramework, owner = @gov_first, account = @0x1)]
  fun test_propose(framework: &signer, owner: &signer, account: &signer) {
    let per_microseconds = 1000 * 1000;
    let day = 24 * 60 * 60;

    initialize_for_test(framework, owner);
    propose(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      1 * day * per_microseconds
    );
    let account_address = signer::address_of(account);
    assert!(voting_mod::exists_proposal<ProConVotingMethod>(1, account_address), 0)
  }
}