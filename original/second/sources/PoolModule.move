module SampleStaking::PoolModule {
  use Std::ASCII;
  use Std::Signer;
  use Std::Event;
  use AptosFramework::Coin;
  use AptosFramework::Timestamp;
  use SampleStaking::LiquidityProviderTokenModule;
  use SampleStaking::Config;

  struct PairPool<phantom X, phantom Y> has key {
    name: ASCII::String,
    lptoken_info: LiquidityProviderTokenModule::LPTokenInfo<X, Y>,
    x: Coin::Coin<X>,
    y: Coin::Coin<Y>,
    last_deposited_timestamp: u64,
    last_withdrawed_timestamp: u64
  }
  struct PoolModuleEventHandle has key {
    deposit_events: Event::EventHandle<DepositEvent>,
    withdraw_events: Event::EventHandle<WithdrawEvent>,
  }

  // struct: events
  struct DepositEvent has drop, store {
    account: address,
    x_amount: u64,
    y_amount: u64,
    timestamp: u64
  }
  struct WithdrawEvent has drop, store {
    account: address,
    x_amount: u64,
    y_amount: u64,
    timestamp: u64
  }

  // consts: Errors
  const E_INVALID_VALUE: u64 = 1;

  // functions: Asserts
  fun assert_greater_than_zero(value: u64) {
    assert!(value > 0, E_INVALID_VALUE);
  }
  fun assert_hold_more_than_amount<CoinType>(account_address: address, value: u64) {
    assert!(Coin::balance<CoinType>(account_address) >= value, E_INVALID_VALUE);
  }

  public fun initialize_module(owner: &signer) {
    Config::assert_admin(owner);
    move_to(owner, PoolModuleEventHandle {
      deposit_events: Event::new_event_handle<DepositEvent>(owner),
      withdraw_events: Event::new_event_handle<WithdrawEvent>(owner)
    })
  }

  public fun add_pair_pool<X, Y>(owner: &signer, name: vector<u8>, x_amount: u64, y_amount: u64) {
    Config::assert_admin(owner);
    assert_greater_than_zero(x_amount);
    assert_greater_than_zero(y_amount);
    let owner_address = Signer::address_of(owner);
    assert_hold_more_than_amount<X>(owner_address, x_amount);
    assert_hold_more_than_amount<Y>(owner_address, y_amount);
    let x = Coin::withdraw<X>(owner, x_amount);
    let y = Coin::withdraw<Y>(owner, y_amount);
    move_to(owner, PairPool<X, Y> {
      name: ASCII::string(name),
      lptoken_info: LiquidityProviderTokenModule::initialize<X, Y>(owner),
      x,
      y,
      last_deposited_timestamp: 0,
      last_withdrawed_timestamp: 0
    });
  }

  public fun deposit<X, Y>(account: &signer, x_amount: u64, y_amount: u64) acquires PairPool, PoolModuleEventHandle {
    assert!(x_amount > 0 || y_amount > 0, E_INVALID_VALUE);
    let account_address = Signer::address_of(account);
    let admin_address = Config::admin_address();
    let pool = borrow_global_mut<PairPool<X, Y>>(admin_address);

    if (x_amount > 0) {
      assert_hold_more_than_amount<X>(account_address, x_amount);
      let coin = Coin::withdraw<X>(account, x_amount);
      Coin::merge<X>(&mut pool.x, coin);
    };
    if (y_amount > 0) {
      assert_hold_more_than_amount<Y>(account_address, y_amount);
      let coin = Coin::withdraw<Y>(account, y_amount);
      Coin::merge<Y>(&mut pool.y, coin);
    };

    if (!LiquidityProviderTokenModule::is_exists<X, Y>(account_address)) {
      LiquidityProviderTokenModule::new<X, Y>(account);
    };
    LiquidityProviderTokenModule::mint_to<X, Y>(
      account_address,
      x_amount + y_amount,
      &mut pool.lptoken_info
    );
    let now_microseconds = Timestamp::now_microseconds();
    pool.last_deposited_timestamp = now_microseconds;

    // emit DepositEvent
    let events = &mut borrow_global_mut<PoolModuleEventHandle>(admin_address).deposit_events;
    Event::emit_event<DepositEvent>(
      events,
      DepositEvent {
        account: account_address,
        x_amount,
        y_amount,
        timestamp: now_microseconds
      }
    );
  }

  public fun withdraw<X, Y>(account: &signer, x_amount: u64, y_amount: u64) acquires PairPool, PoolModuleEventHandle {
    assert!(x_amount > 0 || y_amount > 0, E_INVALID_VALUE);
    let account_address = Signer::address_of(account);
    assert!(LiquidityProviderTokenModule::is_exists<X, Y>(account_address), E_INVALID_VALUE);
    let balance = LiquidityProviderTokenModule::value<X, Y>(account_address);
    assert!(x_amount + y_amount <= balance, E_INVALID_VALUE);

    let admin_address = Config::admin_address();
    let pool = borrow_global_mut<PairPool<X, Y>>(admin_address);
    if (x_amount > 0) {
      let value_in_pool = Coin::value<X>(&pool.x);
      assert!(x_amount <= value_in_pool, E_INVALID_VALUE);

      let coin = Coin::extract<X>(&mut pool.x, x_amount);
      Coin::deposit<X>(account_address, coin);
    };
    if (y_amount > 0) {
      let value_in_pool = Coin::value<Y>(&pool.y);
      assert!(y_amount <= value_in_pool, E_INVALID_VALUE);

      let coin = Coin::extract<Y>(&mut pool.y, y_amount);
      Coin::deposit<Y>(account_address, coin);
    };

    LiquidityProviderTokenModule::burn_from<X, Y>(
      account_address,
      x_amount + y_amount,
      &mut pool.lptoken_info
    );
    let now_microseconds = Timestamp::now_microseconds();
    pool.last_withdrawed_timestamp = now_microseconds;

    // emit WithdrawEvent
    let events = &mut borrow_global_mut<PoolModuleEventHandle>(admin_address).withdraw_events;
    Event::emit_event<WithdrawEvent>(
      events,
      WithdrawEvent {
        account: account_address,
        x_amount,
        y_amount,
        timestamp: now_microseconds
      }
    );
  }

  // #[test_only]
  // use Std::Debug;
  #[test_only]
  use AptosFramework::Coin::{BurnCapability,MintCapability};
  #[test_only]
  struct CoinX {}
  #[test_only]
  struct CoinY {}
  #[test_only]
  struct FakeCapabilities<phantom CoinType> has key {
    mint_cap: MintCapability<CoinType>,
    burn_cap: BurnCapability<CoinType>,
  }
  #[test_only]
  fun register_test_coins(owner: &signer) {
    let (x_mint_cap, x_burn_cap) = Coin::initialize<CoinX>(
      owner,
      ASCII::string(b"Coin X"),
      ASCII::string(b"X"),
      10,
      false
    );
    let (y_mint_cap, y_burn_cap) = Coin::initialize<CoinY>(
      owner,
      ASCII::string(b"Coin Y"),
      ASCII::string(b"Y"),
      10,
      false
    );
    Coin::register_internal<CoinX>(owner);
    Coin::register_internal<CoinY>(owner);

    move_to(owner, FakeCapabilities<CoinX>{
      mint_cap: x_mint_cap,
      burn_cap: x_burn_cap,
    });
    move_to(owner, FakeCapabilities<CoinY>{
      mint_cap: y_mint_cap,
      burn_cap: y_burn_cap,
    });
  }

  #[test(owner = @SampleStaking)]
  fun test_initialize_module(owner: &signer) acquires PoolModuleEventHandle {
    initialize_module(owner);
    let owner_address = Signer::address_of(owner);
    assert!(exists<PoolModuleEventHandle>(owner_address), 0);
    let handle = borrow_global<PoolModuleEventHandle>(owner_address);
    assert!(Event::get_event_handle_counter<DepositEvent>(&handle.deposit_events) == 0, 0);
    assert!(Event::get_event_handle_counter<WithdrawEvent>(&handle.withdraw_events) == 0, 0);
  }

  #[test(owner = @SampleStaking)]
  fun test_add_pair_pool(owner: &signer) acquires PairPool, FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(10000, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(10000, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);

    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 2000, 6000);
    // Check: PairPool
    assert!(exists<PairPool<CoinX, CoinY>>(owner_address), 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    assert!(pool.name == ASCII::string(b"Pool X Y"), 0);
    assert!(LiquidityProviderTokenModule::total_supply_internal<CoinX, CoinY>(&pool.lptoken_info) == 0, 0);
    assert!(Coin::value<CoinX>(&pool.x) == 2000, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 6000, 0);
    // Check: owner
    assert!(Coin::balance<CoinX>(owner_address) == 8000, 0);
    assert!(Coin::balance<CoinY>(owner_address) == 4000, 0);
  }
  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 101)]
  fun test_add_pair_pool_when_not_admin(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 9999, 9999);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  fun test_add_pair_pool_when_x_is_zero(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 0, 9999);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  fun test_add_pair_pool_when_y_is_zero(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 9999, 0);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  fun test_add_pair_pool_when_x_is_insufficient(owner: &signer) acquires FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(1, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(1, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);
    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 5, 1);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  fun test_add_pair_pool_when_y_is_insufficient(owner: &signer) acquires FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(1, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(1, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);
    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 1, 5);
  }

  #[test(core_resources = @CoreResources, owner = @SampleStaking, account = @0x1)]
  fun test_deposit(core_resources: &signer, owner: &signer, account: &signer) acquires PairPool, FakeCapabilities, PoolModuleEventHandle {
    Timestamp::set_time_has_started_for_testing(core_resources);
    initialize_module(owner);
    register_test_coins(owner);
    
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    Coin::deposit<CoinX>(owner_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(owner_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 100, 100);

    let account_address = Signer::address_of(account);
    Coin::register_internal<CoinX>(account);
    Coin::register_internal<CoinY>(account);
    Coin::deposit<CoinX>(account_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(account_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));

    // Execute
    assert!(!LiquidityProviderTokenModule::is_exists<CoinX, CoinY>(account_address), 0);
    
    deposit<CoinX, CoinY>(account, 15, 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(LiquidityProviderTokenModule::is_exists<CoinX, CoinY>(account_address), 0);
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 15, 0);
    assert!(Coin::value<CoinX>(&pool.x) == 115, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 100, 0);
    assert!(Coin::balance<CoinX>(account_address) == 85, 0);
    assert!(Coin::balance<CoinY>(account_address) == 100, 0);
    
    deposit<CoinX, CoinY>(account, 0, 30);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 45, 0);
    assert!(Coin::value<CoinX>(&pool.x) == 115, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 130, 0);
    assert!(Coin::balance<CoinX>(account_address) == 85, 0);
    assert!(Coin::balance<CoinY>(account_address) == 70, 0);
    
    deposit<CoinX, CoinY>(account, 85, 70);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 200, 0);
    assert!(Coin::value<CoinX>(&pool.x) == 200, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 200, 0);
    assert!(Coin::balance<CoinX>(account_address) == 0, 0);
    assert!(Coin::balance<CoinY>(account_address) == 0, 0);

    let handle = borrow_global<PoolModuleEventHandle>(owner_address);
    assert!(Event::get_event_handle_counter<DepositEvent>(&handle.deposit_events) == 3, 0);
    assert!(Event::get_event_handle_counter<WithdrawEvent>(&handle.withdraw_events) == 0, 0);
  }

  #[test(core_resources = @CoreResources, owner = @SampleStaking, account = @0x1)]
  fun test_withdraw(core_resources: &signer, owner: &signer, account: &signer) acquires PairPool, FakeCapabilities, PoolModuleEventHandle {
    Timestamp::set_time_has_started_for_testing(core_resources);
    initialize_module(owner);
    register_test_coins(owner);

    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    Coin::deposit<CoinX>(owner_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(owner_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 1, 1);

    let account_address = Signer::address_of(account);
    Coin::register_internal<CoinX>(account);
    Coin::register_internal<CoinY>(account);
    Coin::deposit<CoinX>(account_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(account_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));

    // Execute
    deposit<CoinX, CoinY>(account, 100, 100);

    withdraw<CoinX, CoinY>(account, 15, 0);
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 185, 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(Coin::value<CoinX>(&pool.x) == 86, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 101, 0);
    assert!(Coin::balance<CoinX>(account_address) == 15, 0);
    assert!(Coin::balance<CoinY>(account_address) == 0, 0);

    withdraw<CoinX, CoinY>(account, 0, 30);
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 155, 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(Coin::value<CoinX>(&pool.x) == 86, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 71, 0);
    assert!(Coin::balance<CoinX>(account_address) == 15, 0);
    assert!(Coin::balance<CoinY>(account_address) == 30, 0);

    withdraw<CoinX, CoinY>(account, 85, 70);
    assert!(LiquidityProviderTokenModule::value<CoinX, CoinY>(account_address) == 0, 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    // Debug::print<u64>(&pool.last_deposited_timestamp); // For debug
    // Debug::print<u64>(&pool.last_withdrawed_timestamp); // For debug
    assert!(Coin::value<CoinX>(&pool.x) == 1, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 1, 0);
    assert!(Coin::balance<CoinX>(account_address) == 100, 0);
    assert!(Coin::balance<CoinY>(account_address) == 100, 0);

    let handle = borrow_global<PoolModuleEventHandle>(owner_address);
    assert!(Event::get_event_handle_counter<DepositEvent>(&handle.deposit_events) == 1, 0);
    assert!(Event::get_event_handle_counter<WithdrawEvent>(&handle.withdraw_events) == 3, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_withdraw_with_zero_value(account: &signer) acquires PairPool, PoolModuleEventHandle {
    withdraw<CoinX, CoinY>(account, 0, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_withdraw_with_no_lptoken(account: &signer) acquires PairPool, PoolModuleEventHandle {
    withdraw<CoinX, CoinY>(account, 1, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_withdraw_with_no_balance_of_lptoken(account: &signer) acquires PairPool, PoolModuleEventHandle {
    LiquidityProviderTokenModule::new<CoinX, CoinY>(account);
    withdraw<CoinX, CoinY>(account, 1, 0);
  }
  #[test(core_resources = @CoreResources, owner = @SampleStaking, account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_withdraw_with_insufficent_coin_x_in_pool(core_resources: &signer, owner: &signer, account: &signer) acquires PairPool, FakeCapabilities, PoolModuleEventHandle {
    Timestamp::set_time_has_started_for_testing(core_resources);
    initialize_module(owner);
    register_test_coins(owner);

    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    Coin::deposit<CoinX>(owner_address, Coin::mint<CoinX>(1, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(owner_address, Coin::mint<CoinY>(1, &y_capabilities.mint_cap));
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 1, 1);

    let account_address = Signer::address_of(account);
    Coin::register_internal<CoinX>(account);
    Coin::register_internal<CoinY>(account);
    Coin::deposit<CoinX>(account_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(account_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));
    deposit<CoinX, CoinY>(account, 100, 100);

    // Execute
    withdraw<CoinX, CoinY>(account, 102, 0);
  }
  #[test(core_resources = @CoreResources, owner = @SampleStaking, account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_withdraw_with_insufficent_coin_y_in_pool(core_resources: &signer, owner: &signer, account: &signer) acquires PairPool, FakeCapabilities, PoolModuleEventHandle {
    Timestamp::set_time_has_started_for_testing(core_resources);
    initialize_module(owner);
    register_test_coins(owner);

    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    Coin::deposit<CoinX>(owner_address, Coin::mint<CoinX>(1, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(owner_address, Coin::mint<CoinY>(1, &y_capabilities.mint_cap));
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 1, 1);

    let account_address = Signer::address_of(account);
    Coin::register_internal<CoinX>(account);
    Coin::register_internal<CoinY>(account);
    Coin::deposit<CoinX>(account_address, Coin::mint<CoinX>(100, &x_capabilities.mint_cap));
    Coin::deposit<CoinY>(account_address, Coin::mint<CoinY>(100, &y_capabilities.mint_cap));
    deposit<CoinX, CoinY>(account, 100, 100);

    // Execute
    withdraw<CoinX, CoinY>(account, 0, 102);
  }
}