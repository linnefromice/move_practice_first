#[test_only]
module gov_first::test_base_mod {
  use std::signer;
  use aptos_framework::simple_map::{Self, SimpleMap};

  struct TestMapItem<Kind> has store {
    kind: Kind,
    level: u64,
    getted_at: u64,
  }
  struct TestMap<Kind> has key {
    items: SimpleMap<u64, TestMapItem<Kind>>
  }

  // For General
  fun publish_map<Kind: store>(account: &signer) {
    let account_address = signer::address_of(account);
    assert!(!exists<TestMap<Kind>>(account_address), 0);
    move_to(account, TestMap<Kind> {
      items: simple_map::create<u64, TestMapItem<Kind>>()
    })
  }

  // #[test_only]
  // struct TestKind has store {}
  // #[test(account = @0x1)]
  // fun test_publish_item_box(account: &signer) {
  //   publish_map<TestKind>(account);
  //   let account_address = signer::address_of(account);
  //   assert!(exists<TestMap<TestKind>>(account_address), 0);
  // } // <- fail
}