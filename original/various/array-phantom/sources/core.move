module array_phantom::core {
  use std::vector;
  use std::table::{Self, Table};
  use std::simple_map::{Self, SimpleMap};

  struct VectorWrapper<T> has key {
    vector: vector<T>,
  }
  struct TableWrapper<phantom T> has key {
    table: Table<u64, T>, 
  }
  struct SimpleMapWrapper<T> has key {
    map: SimpleMap<u64, T>,
  }

  public fun publish<T: store>(owner: &signer) {
    move_to(owner, VectorWrapper<T>{ vector: vector::empty<T>() });
    move_to(owner, TableWrapper<T>{ table: table::new<u64, T>() });
    move_to(owner, SimpleMapWrapper<T>{ map: simple_map::create<u64, T>() });
  }

  #[test_only]
  use std::signer;
  #[test_only]
  struct TestCoreCoin has store {}
  #[test(account = @0x1)]
  fun test_publish(account: &signer) {
    publish<TestCoreCoin>(account);
    let account_address = signer::address_of(account);
    assert!(exists<VectorWrapper<TestCoreCoin>>(account_address), 0);
    assert!(exists<TableWrapper<TestCoreCoin>>(account_address), 0);
    assert!(exists<SimpleMapWrapper<TestCoreCoin>>(account_address), 0);
  }
}