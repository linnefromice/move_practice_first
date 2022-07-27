#[test_only]
module gov_first::test_two_mod {
  use std::signer;
  use std::string;
  use aptos_framework::table::{Self, Table};

  struct Sword has store {
    attack: u64,
    both_hands: bool,
  }
  struct Spear has store {
    attack: u64,
    length: u64,
  }
  struct Wand has store {
    magic_power: u64,
    is_white: bool,
    is_black: bool,
  }
  struct Gun has store {
    power: u64,
    range: u64,
    capacity: u64,
    shooting_rate: u64,
    kind: string::String,
  }
  struct Portion has store {
    value: u64
  }

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
    add_item<Sword>(account, Item<Sword> { kind: Sword { attack: 100, both_hands: false }, level: 50, getted_at: 0 });
    add_item<Spear>(account, Item<Spear> { kind: Spear { attack: 50, length: 50 }, level: 50, getted_at: 0 });
    add_item<Wand>(account, Item<Wand> { kind: Wand { magic_power: 200, is_white: true, is_black: true }, level: 50, getted_at: 0 });
    // add_item<Gun>(account, Item<Gun> { kind: Gun {}, level: 50, getted_at: 0 });
    add_item<Portion>(account, Item<Portion> { kind: Portion { value: 300 }, level: 50, getted_at: 0 });
    add_item<Portion>(account, Item<Portion> { kind: Portion { value: 500 }, level: 50, getted_at: 0 });
    add_item<Portion>(account, Item<Portion> { kind: Portion { value: 1000 }, level: 50, getted_at: 0 });
    let account_address = signer::address_of(account);
    assert!(table::length<u64, Item<Sword>>(&borrow_global_mut<ItemBox<Sword>>(account_address).items) == 1, 0);
    assert!(table::length<u64, Item<Spear>>(&borrow_global_mut<ItemBox<Spear>>(account_address).items) == 1, 0);
    assert!(table::length<u64, Item<Wand>>(&borrow_global_mut<ItemBox<Wand>>(account_address).items) == 1, 0);
    assert!(table::empty<u64, Item<Gun>>(&borrow_global_mut<ItemBox<Gun>>(account_address).items), 0);
    assert!(table::length<u64, Item<Portion>>(&borrow_global_mut<ItemBox<Portion>>(account_address).items) == 3, 0);
  }
}
