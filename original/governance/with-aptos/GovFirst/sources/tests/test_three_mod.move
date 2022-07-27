#[test_only]
module gov_first::test_three_mod {
  use std::signer;
  use aptos_framework::table::{Self, Table};

  struct Item has store {
    no: u64
  }
  struct Box has key {
    items: Table<u64, Item>
  }

  fun publish_box(account: &signer) {
    move_to(account, Box { items: table::new() });
  }
  fun add_item(account: &signer, no: u64) acquires Box {
    let account_addreess = signer::address_of(account);
    let box = borrow_global_mut<Box>(account_addreess);
    let length = table::length<u64, Item>(&box.items);
    table::add<u64, Item>(&mut box.items, length + 1, Item { no })
  }
  // fun find_item(account: &signer, key: u64): &Item acquires Box {
  //   let account_addreess = signer::address_of(account);
  //   let box = borrow_global<Box>(account_addreess);
  //   table::borrow<u64, Item>(&box.items, key)
  // }
  fun find_item(account: &signer, key: u64): u64 acquires Box {
    let account_addreess = signer::address_of(account);
    let box = borrow_global<Box>(account_addreess);
    let item = table::borrow<u64, Item>(&box.items, key);
    item.no
  }
}