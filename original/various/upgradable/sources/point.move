module original::point {
  use std::signer;
  use std::vector;

  struct PointBox has key {
    points: vector<Point>,
  }

  struct Point has store {
    value: u64
  }

  struct PointCounter has key {
    count: u64
  }

  public entry fun initialize(owner: &signer) {
    move_to(owner, PointBox {
      points: vector::empty<Point>()
    });
    move_to(owner, PointCounter { count: 0 });
  }

  public entry fun initialize_index(owner: &signer) acquires PointBox {
    let owner_address = signer::address_of(owner);
    let points = &borrow_global<PointBox>(owner_address).points;
    move_to(owner, PointCounter {
      count: vector::length<Point>(points)
    })
  }


  public entry fun add_point(owner: &signer, value: u64) acquires PointBox, PointCounter {
    let owner_address = signer::address_of(owner);
    let points = &mut borrow_global_mut<PointBox>(owner_address).points;
    vector::push_back<Point>(points, Point { value: value + 100 });

    let counter = borrow_global_mut<PointCounter>(owner_address);
    counter.count = counter.count + 1;
  }

  #[test(account = @0x1)]
  fun test_end_to_end(account: &signer) acquires PointBox, PointCounter {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(exists<PointBox>(account_address), 0);
    add_point(account, 1);
    add_point(account, 2);
    let points = &borrow_global<PointBox>(account_address).points;
    assert!(vector::length<Point>(points) == 2, 0);
  }
}