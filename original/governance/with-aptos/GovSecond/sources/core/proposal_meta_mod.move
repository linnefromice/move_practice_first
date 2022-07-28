module gov_second::proposal_meta_mod {
  use std::string;

  struct ProposalMeta has store {
    title: string::String,
    content: string::String,
    proposer: address,
    expiration_secs: u64,
    created_at: u64,
    updated_at: u64
  }

  public fun create_proposal_meta(
    title: string::String,
    content: string::String,
    proposer: address,
    expiration_secs: u64,
    created_at: u64,
    updated_at: u64
  ): ProposalMeta {
    ProposalMeta {
      title,
      content,
      proposer,
      expiration_secs,
      created_at,
      updated_at
    }
  }

  #[test_only]
  use std::signer;
  #[test_only]
  struct TestContainer has key { meta: ProposalMeta }
  #[test(account = @0x1)]
  fun test_create_proposal_meta(account: &signer) {
    let account_address = signer::address_of(account);
    let proposal_meta = create_proposal_meta(
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
      account_address,
      0,
      0,
      0,
    );

    move_to(account, TestContainer { meta: proposal_meta } );
  }
}