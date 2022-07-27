#[test_only]
module gov_first::test_two_mod {
  use std::signer;
  use aptos_framework::table::{Self, Table};

  struct Sword has store {}
  struct Spear has store {}
  struct Wand has store {}
  struct Gun has store {}
  struct Portion has store {}

  struct Item<Kind> has store {
    kind: Kind,
    level: u64,
    getted_at: u64,
  }
  
  struct ItemBox<Kind> has key {
    items: Table<u64, Item<Kind>>
  }

  fun publish_item_box<Kind: store>(account: &signer) {
    move_to(account, ItemBox<Kind> {
      items: table::new()
    })
  }

  #[test(account = @0x1)]
  fun test_publish_item_box(account: &signer) {
    publish_item_box<Sword>(account);
    publish_item_box<Portion>(account);
    let account_address = signer::address_of(account);
    assert!(exists<ItemBox<Sword>>(account_address), 0);
    assert!(!exists<ItemBox<Spear>>(account_address), 0);
    assert!(!exists<ItemBox<Wand>>(account_address), 0);
    assert!(!exists<ItemBox<Gun>>(account_address), 0);
    assert!(exists<ItemBox<Portion>>(account_address), 0);
  }
}
