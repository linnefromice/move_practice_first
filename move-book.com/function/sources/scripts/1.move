script {
  use 0x1::debug;
  use 0x2::Math;

  fun main(first_num: u64, second_num: u64) {
    let sum = Math::sum(first_num, second_num);

    debug::print<u64>(&sum);
  }
}
