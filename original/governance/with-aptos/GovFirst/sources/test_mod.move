#[test_only]
module gov_first::test_mod {
  use aptos_framework::timestamp;

  #[test(framework = @AptosFramework)]
  fun test_use_timestamp_in_test(framework: &signer) {
    timestamp::set_time_has_started_for_testing(framework);
    let current = timestamp::now_microseconds();
    assert!(current == 0, 0);
  }
}
