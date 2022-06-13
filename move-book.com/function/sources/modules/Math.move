address 0x2 {
  module Math {
    public fun sum(a: u64, b: u64): u64 {
      a + b
    }

    fun zero(): u8 {
      0
    }

    public fun max(a: u64, b: u64): (u64, bool) {
      if (a > b) {
        (a, false)
      } else if (a < b) {
        (b, false)
      } else {
        (a, true)
      }
    }
  }
}
