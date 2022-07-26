module gov_first::ballot_box_mod {
  use gov_first::proposal_mod::Proposal;

  struct IdCounter has key {
    value: u64
  }

  struct BalletBox has key {
    uid: u64,
    proposal: Proposal,
  }
}