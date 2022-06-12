address 0x2 {
  module Math {
    public fun sum(a: u64, b: u64): u64 {
      a + b
    }

    fun zero(): u8 {
      0
    }
  }
}
