script {
  use 0x1::debug;
  use 0x2::Math;

  fun main(a: u64, b: u64) {
    let (_num, _bool) = Math::max(a, b);

    debug::print<u64>(&_num);
    debug::print<bool>(&_bool);
  }
}
