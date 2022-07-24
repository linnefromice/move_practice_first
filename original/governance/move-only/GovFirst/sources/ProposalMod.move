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
}