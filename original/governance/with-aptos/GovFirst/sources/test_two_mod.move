#[test_only]
module gov_first::test_two_mod {
  use std::signer;
  use aptos_framework::table::{Self, Table};

  struct Sword has store {}
  struct Item<Kind> has store {
    value: u64,
    kind: Kind,
  }
  
  struct ItemBox<Kind> has key {
    items: Table<u64, Item<Kind>>
  }

  fun publish_item_box(account: &signer) {
    move_to(account, ItemBox<Sword> {
      items: table::new()
    })
  }

  #[test(account = @0x1)]
  fun test_publish_item_box(account: &signer) {
    publish_item_box(account);
    let account_address = signer::address_of(account);
    assert!(exists<ItemBox<Sword>>(account_address), 0);
  }
}
