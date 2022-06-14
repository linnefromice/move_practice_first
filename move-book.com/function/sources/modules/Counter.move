module 0x6::Counter {
  use std::signer;

  struct Counter has key { i: u64 }

  /// Publish a `Counter` resource with value `i` under the given account
  public fun publish(account: &signer, i: u64) {
    // "Pack" (create) a Counter resource.
    // This is a privileged operation that can only be done inside the module that declares the `Counter` resource
    move_to(account, Counter { i })
  }

  /// Read the value in the `Counter` resource stored at `addr`
  public fun get_count(addr: address): u64 acquires Counter {
    borrow_global<Counter>(addr).i
  }

  /// Increment the value of `addr`'s `Counter` resource
  public fun increment(addr: address) acquires Counter {
    let c_ref = &mut borrow_global_mut<Counter>(addr).i;
    *c_ref = *c_ref + 1
  }

  /// Reset the value of `accounts`'s `Counter` to 0
  public fun reset(account: &signer) acquires Counter {
    let c_ref = &mut borrow_global_mut<Counter>(signer::address_of(account)).i;
    *c_ref = 0
  }

  /// Delete the `Counter` resource under `account` and return its value
  public fun delete(account: &signer): u64 acquires Counter {
    // remove the Counter resource
    let c = move_from<Counter>(signer::address_of(account));
    // "Unpack" the `Counter` resource into its fields.
    // This is a priviledged operation that can only be done inside the module
    // that declares the `Counter` resource
    let Counter { i } = c;
    i
  }

  /// Return `true` if `addr` contains a `Counter` resource
  public fun existsInAddr(addr: address): bool {
    exists<Counter>(addr)
  }
}
