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

  fun add_item<Kind: store>(account: &signer, item: Item<Kind>) acquires ItemBox {
    let account_address = signer::address_of(account);
    assert!(exists<ItemBox<Kind>>(account_address), 0);
    let box = borrow_global_mut<ItemBox<Kind>>(account_address);
    let length = table::length<u64, Item<Kind>>(&box.items);
    table::add<u64, Item<Kind>>(&mut box.items, length + 1, item);
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
  #[test(account = @0x1)]
  fun test_add_item(account: &signer) acquires ItemBox {
    publish_item_box<Sword>(account);
    publish_item_box<Spear>(account);
    publish_item_box<Wand>(account);
    publish_item_box<Gun>(account);
    publish_item_box<Portion>(account);
    add_item<Sword>(account, Item<Sword> { kind: Sword {}, level: 50, getted_at: 0 });
    add_item<Spear>(account, Item<Spear> { kind: Spear {}, level: 50, getted_at: 0 });
    add_item<Wand>(account, Item<Wand> { kind: Wand {}, level: 50, getted_at: 0 });
    add_item<Gun>(account, Item<Gun> { kind: Gun {}, level: 50, getted_at: 0 });
    add_item<Portion>(account, Item<Portion> { kind: Portion {}, level: 50, getted_at: 0 });
  }
}
