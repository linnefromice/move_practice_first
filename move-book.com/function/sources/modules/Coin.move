address 0x3 {
  module Coin {
    struct Coin has store {
      value: u64,
    }

    public fun mint(value: u64): Coin {
      Coin { value }
    }

    public fun withdraw(coin: &mut Coin, amount: u64): Coin {
      assert!(coin.value >= amount, 1000);
      coin.value = coin.value - amount;
      Coin { value: amount }
    }

    public fun deposit(coin: &mut Coin, other: Coin) {
      let Coin { value } = other;
      coin.value = coin.value + value;
    }

    public fun split(coin: Coin, amount: u64): (Coin, Coin) {
      let other = withdraw(&mut coin, amount);
      (coin, other)
    }

    public fun destroy_zero(coin: Coin) {
      let Coin { value } = coin;
      assert!(value == 0, 1001)
    }
  }
}
