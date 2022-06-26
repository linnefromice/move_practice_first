module BasicCoin::BasicCoin {
  use std::errors;
  use std::signer;

  /// Error Codes
  const ENOT_MODULE_OWNER : u64 = 0;
  const ESUFFICIENT_BALANCE: u64 = 1;
  const EALREADY_HAS_BALANCE: u64 = 2;
  const EALREADY_INITIALIZED: u64 = 3;
  const EEQUAL_ADDR: u64 = 4;

  struct Coin<phantom CoinType> has store {
    value: u64
  }

  struct Balance<phantom CoinType> has key {
    coin: Coin<CoinType>
  }

  public fun publish_balance<CoinType>(account: &signer) {
    let empty_coin = Coin<CoinType> { value: 0 };
    assert!(!exists<Balance<CoinType>>(signer::address_of(account)), errors::already_published(EALREADY_HAS_BALANCE));
    move_to(account, Balance<CoinType> { coin: empty_coin });
  }
}