script {
  use 0x1::debug;
  use 0x42::ExampleCalling;

  fun sampleTwo() {
    let num0 = ExampleCalling::takes_none();
    let num1 = ExampleCalling::takes_one(1);
    let num2 = ExampleCalling::takes_two(1, 2);
    let num3 = ExampleCalling::takes_three(1, 2, 3);
    debug::print<u64>(&num0);
    debug::print<u64>(&num1);
    debug::print<u64>(&num2);
    debug::print<u64>(&num3);
  }
}