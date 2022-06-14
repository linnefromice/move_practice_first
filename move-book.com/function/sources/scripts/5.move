script {
  use 0x1::debug;
  use 0x1::vector;

  fun main() {
    let a = vector::empty<u8>();
    let i = 0;

    while (i < 10) {
      vector::push_back(&mut a, i);
      i = i + 1;
    };

    let a_len = vector::length(&a);
    debug::print<u64>(&a_len);

    vector::pop_back(&mut a);
    vector::pop_back(&mut a);

    let a_len = vector::length(&a);
    debug::print<u64>(&a_len);
  }
}