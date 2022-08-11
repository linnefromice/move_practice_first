#[test_only]
module array_phantom::timestamp_test {
  use aptos_framework::timestamp;

  #[test(aptos_framework = @0x1)]
  fun test_scenario(aptos_framework: &signer) {
    timestamp::set_time_has_started_for_testing(aptos_framework);
    assert!(timestamp::now_microseconds() == 0, 0);
    assert!(timestamp::now_seconds() == 0, 0);
    timestamp::fast_forward_seconds(1);
    assert!(timestamp::now_microseconds() == 1000000, 0);
    assert!(timestamp::now_seconds() == 1, 0);
  }
}