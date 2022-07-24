module GovFirst::ProposalMod {
  use std::signer;
  use std::string;

  struct Proposal has key {
    title: string::String,
    content: string::String,
    proposer: address,
  }

  fun create_proposal(proposer: &signer, title: string::String, content: string::String): Proposal {
    let proposer_address = signer::address_of(proposer);
    Proposal {
      title,
      content,
      proposer: proposer_address
    }
  }

  #[test(proposer = @0x1)]
  fun test_create_proposal(proposer: &signer) {
    let proposal = create_proposal(
      proposer,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let proposer_address = signer::address_of(proposer);
    assert!(proposal.title == string::utf8(b"proposal_title"), 0);
    assert!(proposal.content == string::utf8(b"proposal_content"), 0);
    assert!(proposal.proposer == proposer_address, 0);
    move_to(proposer, proposal);
  }
}
