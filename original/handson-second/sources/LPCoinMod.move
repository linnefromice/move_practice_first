module HandsonSecond::LPCoinMod {
  use Std::Signer;

  struct LPCoinStatus has key {
    total_supply: u64,
    holder_count: u64
  }
  struct LPCoin has key {
    value: u64
  }

  // Functions: Operate for owner
  public fun initialize(owner: &signer) {
    let owner_address = Signer::address_of(owner);
    assert!(owner_address == @HandsonSecond, 0);

    move_to(owner, LPCoinStatus {
      total_supply: 0,
      holder_count: 0
    });
  }
  fun increment_holder_count() acquires LPCoinStatus {
    let status = borrow_global_mut<LPCoinStatus>(@HandsonSecond);
    status.holder_count = status.holder_count + 1;
  }
  fun increment_total_supply(amount: u64) acquires LPCoinStatus {
    let status = borrow_global_mut<LPCoinStatus>(@HandsonSecond);
    status.total_supply = status.total_supply + amount;
  }
  fun decrement_total_supply(amount: u64) acquires LPCoinStatus {
    let status = borrow_global_mut<LPCoinStatus>(@HandsonSecond);
    status.total_supply = status.total_supply - amount;
  }

  // Functions: Operate for users
  public(script) fun new_script(to: &signer) acquires LPCoinStatus {
    new(to);
  }
  public fun new(to: &signer) acquires LPCoinStatus {
    move_to(to, new_internal());
    increment_holder_count();
  }
  public fun new_internal(): LPCoin {
    LPCoin { value: 0 }
  }

  public fun mint(to: address, amount: u64) acquires LPCoin, LPCoinStatus {
    let coin = borrow_global_mut<LPCoin>(to);
    mint_internal(coin, amount);
    increment_total_supply(amount);
  }
  public fun mint_internal(coin: &mut LPCoin, amount: u64) {
    coin.value = coin.value + amount;
  }

  public fun burn(to: address, amount: u64) acquires LPCoin, LPCoinStatus {
    let coin = borrow_global_mut<LPCoin>(to);
    burn_internal(coin, amount);
    decrement_total_supply(amount);
  }
  public fun burn_internal(coin: &mut LPCoin, amount: u64) {
    coin.value = coin.value - amount;
  }

  // Functions: Getters
  public fun value(account_address: address): u64 acquires LPCoin {
    let coin = borrow_global_mut<LPCoin>(account_address);
    value_internal(coin)
  }
  public fun value_internal(coin: &LPCoin): u64 {
    coin.value
  }
  public fun is_exist(account_address: address): bool {
    exists<LPCoin>(account_address)
  }
  public fun total_supply(): u64 acquires LPCoinStatus {
    let status = borrow_global<LPCoinStatus>(@HandsonSecond);
    status.total_supply
  }
  public fun holder_count(): u64 acquires LPCoinStatus {
    let status = borrow_global<LPCoinStatus>(@HandsonSecond);
    status.holder_count
  }

  #[test(owner = @HandsonSecond)]
  fun test_initialize(owner: &signer) acquires LPCoinStatus {
    initialize(owner);
    let owner_address = Signer::address_of(owner);
    assert!(exists<LPCoinStatus>(owner_address), 0);
    let status_ref = borrow_global<LPCoinStatus>(owner_address);
    assert!(status_ref.total_supply == 0, 0);
    assert!(status_ref.holder_count == 0, 0);
  }
  #[test(owner = @HandsonSecond, to = @0x1)]
  fun test_new(owner: &signer, to: &signer) acquires LPCoinStatus {
    initialize(owner);
    new(to);
    let to_address = Signer::address_of(to);
    assert!(exists<LPCoin>(to_address), 0);

    let owner_address = Signer::address_of(owner);
    let status_ref = borrow_global<LPCoinStatus>(owner_address);
    assert!(status_ref.total_supply == 0, 0);
    assert!(status_ref.holder_count == 1, 0);
  }
  #[test(owner = @HandsonSecond, to = @0x1)]
  fun test_mint(owner: &signer, to: &signer) acquires LPCoin, LPCoinStatus {
    initialize(owner);
    new(to);
    let to_address = Signer::address_of(to);
    mint(to_address, 50);
    let coin_ref = borrow_global<LPCoin>(to_address);
    assert!(coin_ref.value == 50, 0);

    let owner_address = Signer::address_of(owner);
    let status_ref = borrow_global<LPCoinStatus>(owner_address);
    assert!(status_ref.total_supply == 50, 0);
    assert!(status_ref.holder_count == 1, 0);
  }
  #[test(owner = @HandsonSecond, to = @0x1)]
  fun test_burn(owner: &signer, to: &signer) acquires LPCoin, LPCoinStatus {
    initialize(owner);
    new(to);
    let to_address = Signer::address_of(to);
    mint(to_address, 50);
    burn(to_address, 35);
    let coin_ref = borrow_global<LPCoin>(to_address);
    assert!(coin_ref.value == 15, 0);

    let owner_address = Signer::address_of(owner);
    let status_ref = borrow_global<LPCoinStatus>(owner_address);
    assert!(status_ref.total_supply == 15, 0);
    assert!(status_ref.holder_count == 1, 0);
  }
}