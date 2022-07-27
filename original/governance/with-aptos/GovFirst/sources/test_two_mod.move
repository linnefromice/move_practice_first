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

  // For General
  fun publish_item_box<Kind: store>(account: &signer) {
    let account_address = signer::address_of(account);
    assert!(!exists<ItemBox<Kind>>(account_address), 0);
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
  fun get_item<Kind: store>(item: &Item<Kind>): (&Kind, u64, u64) {
    (&item.kind, item.level, item.getted_at)
  }
  // fun find_item<Kind: copy + store>(account_address: address, key: u64): (&Kind, u64, u64) acquires ItemBox {
  //   assert!(exists<ItemBox<Kind>>(account_address), 0);
  //   let box = borrow_global<ItemBox<Kind>>(account_address);
  //   let item = table::borrow<u64, Item<Kind>>(&box.items, key);
  //   get_item<Kind>(item)
  // } // <- NG
  // fun find_item<Kind: copy + store>(account_address: address, key: u64): (Kind, u64, u64) acquires ItemBox {
  //   assert!(exists<ItemBox<Kind>>(account_address), 0);
  //   let box = borrow_global<ItemBox<Kind>>(account_address);
  //   let item = table::borrow<u64, Item<Kind>>(&box.items, key);
  //   (item.kind, item.level, item.getted_at)
  // } // <- OK
  // fun find_item<Kind: store>(account_address: address, key: u64): &Item<Kind> acquires ItemBox {
  //   assert!(exists<ItemBox<Kind>>(account_address), 0);
  //   let box = borrow_global<ItemBox<Kind>>(account_address);
  //   let item = table::borrow<u64, Item<Kind>>(&box.items, key);
  //   item
  // } // <- NG

  // For Sword
  fun add_sword(account: &signer, level: u64, attack: u64, both_hands: bool) acquires ItemBox {
    let item = Item<Sword> {
      kind: Sword { attack, both_hands },
      level,
      getted_at: 0
    };
    add_item<Sword>(account, item);
  }
  fun find_sword(account_address: address, key: u64): (u64, u64, bool) acquires ItemBox {
    assert!(exists<ItemBox<Sword>>(account_address), 0);
    let box = borrow_global<ItemBox<Sword>>(account_address);
    let item = table::borrow<u64, Item<Sword>>(&box.items, key);
    (item.level, item.kind.attack, item.kind.both_hands)
  }

  // For Portion
  fun add_portion(account: &signer, level: u64, value: u64) acquires ItemBox {
    let item = Item<Portion> {
      kind: Portion { value },
      level,
      getted_at: 0
    };
    add_item<Portion>(account, item);
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
  #[expected_failure(abort_code = 0)]
  fun test_publish_item_box_twice(account: &signer) {
    publish_item_box<Sword>(account);
    publish_item_box<Sword>(account);
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
  #[test(account = @0x1)]
  fun test_add_item_by_exclusive_functions(account: &signer) acquires ItemBox {
    let account_address = signer::address_of(account);

    publish_item_box<Sword>(account);
    add_sword(account, 10, 15, false);
    add_sword(account, 10, 10, false);
    add_sword(account, 50, 2500, true);
    assert!(table::length<u64, Item<Sword>>(&borrow_global_mut<ItemBox<Sword>>(account_address).items) == 3, 0);

    publish_item_box<Portion>(account);
    add_portion(account, 25, 1000);
    add_portion(account, 25, 1000);
    add_portion(account, 25, 1000);
    add_portion(account, 25, 1000);
    add_portion(account, 25, 1000);
    assert!(table::length<u64, Item<Portion>>(&borrow_global_mut<ItemBox<Portion>>(account_address).items) == 5, 0);
  }
  #[test(account = @0x1)]
  fun test_find_sword(account: &signer) acquires ItemBox {
    let account_address = signer::address_of(account);

    publish_item_box<Sword>(account);
    add_sword(account, 10, 15, false);
    add_sword(account, 10, 10, false);
    add_sword(account, 50, 2500, true);
    let (level, attack, both_hands) = find_sword(account_address, 2);
    assert!(level == 10, 0);
    assert!(attack == 10, 0);
    assert!(both_hands == false, 0);
  }
}
