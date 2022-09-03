module original::point {
  use std::signer;
  use std::vector;

  struct PointBox has key {
    points: vector<Point>,
  }

  struct Point has store {
    value: u64
  }

  public entry fun initialize(owner: &signer) {
    move_to(owner, PointBox {
      points: vector::empty<Point>()
    })
  }

  public entry fun add_point(owner: &signer, value: u64) acquires PointBox {
    let owner_address = signer::address_of(owner);
    let points = &mut borrow_global_mut<PointBox>(owner_address).points;
    vector::push_back<Point>(points, Point { value });
  }

  #[test(account = @0x1)]
  fun test_end_to_end(account: &signer) acquires PointBox {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(exists<PointBox>(account_address), 0);
    add_point(account, 1);
    add_point(account, 2);
    let points = &borrow_global<PointBox>(account_address).points;
    assert!(vector::length<Point>(points) == 2, 0);
  }
}