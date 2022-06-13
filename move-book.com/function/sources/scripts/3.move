script {
  use 0x1::debug;
  use 0x42::ExampleCalling;

  fun sampleOne() {
    let num1 = 0x42::ExampleCalling::zero();
    let num2 = ExampleCalling::zero();
    // let num3 = zero();
    debug::print<u64>(&num1);
    debug::print<u64>(&num2);
    // debug::print<u64>(&num3);
  }
}