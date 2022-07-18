module Handson::CounterMod {
  use Std::Signer;

  struct Counter has key {
    value: u64
  }

  const ENO_COUNTER: u64 = 1;

  public fun publish_data(owner: &signer) {
    move_to(owner, Counter { value: 0 });
  }

  public fun add(account: &signer) acquires Counter {
    let account_address = Signer::address_of(account);
    assert!(exists<Counter>(account_address), ENO_COUNTER);
    let counter_ref = borrow_global_mut<Counter>(account_address);
    counter_ref.value = counter_ref.value + 1;
  }

  public fun remove(account: &signer) acquires Counter {
    let account_address = Signer::address_of(account);
    assert!(exists<Counter>(account_address), ENO_COUNTER);
    let value_ref = &mut borrow_global_mut<Counter>(account_address).value;
    *value_ref = *value_ref - 1;
  }

  #[test(account = @0x1)]
  fun test_publish_data(account: &signer) acquires Counter {
    publish_data(account);
    let account_address = Signer::address_of(account);
    assert!(exists<Counter>(account_address), 0);
    let counter_ref = borrow_global<Counter>(account_address);
    assert!(counter_ref.value == 0, 0);
  }

  #[test(account = @0x1)]
  fun test_add(account: &signer) acquires Counter {
    publish_data(account);
    add(account);
    add(account);
    add(account);
    let account_address = Signer::address_of(account);
    let counter_ref = borrow_global<Counter>(account_address);
    assert!(counter_ref.value == 3, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_add_without_resource(account: &signer) acquires Counter {
    add(account);
  }
  #[test(account = @0x1)]
  fun test_remove(account: &signer) acquires Counter {
    publish_data(account);
    add(account);
    add(account);
    remove(account);
    let account_address = Signer::address_of(account);
    let counter_ref = borrow_global<Counter>(account_address);
    assert!(counter_ref.value == 1, 0);
  }
}