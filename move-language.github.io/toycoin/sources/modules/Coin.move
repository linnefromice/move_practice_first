address 0x2 {
  module Coin {
    struct Coin has drop {
      value: u64,
    }

    public fun mint(value: u64): Coin {
      Coin { value }
    }

    public fun value(coin: &Coin): u64 {
      coin.value
    }

    public fun burn(coin: Coin): u64 {
      let Coin { value } = coin;
      value
    }
  }
}
