module basics::one_time_witness_registry {
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use std::string::String;
    use sui::transfer;

    use sui::types;
    
    const ENotOneTimeWitness: u64 = 0;

    struct UniqueTypeRecord<phantom T> has key {
        id: UID,
        name: String
    }

    public fun add_record<T: drop>(
        witness: T,
        name: String,
        ctx: &mut TxContext
    ) {
        assert!(types::is_one_time_witness(&witness), ENotOneTimeWitness);

        transfer::share_object(UniqueTypeRecord<T> {
            id: object::new(ctx),
            name
        });
    }
}

module basics::my_otw_first {
    use std::string;
    use sui::tx_context::TxContext;
    use basics::one_time_witness_registry as registry;

    struct MY_OTW_FIRST has drop {}

    fun init(witness: MY_OTW_FIRST, ctx: &mut TxContext) {
        registry::add_record(
            witness,
            string::utf8(b"My awesome record"),
            ctx
        )
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        init(MY_OTW_FIRST {}, ctx);
    }
}

module basics::my_otw_second {
    use std::string;
    use sui::tx_context::TxContext;
    use basics::one_time_witness_registry as registry;

    struct MY_OTW_SECOND has drop {}

    fun init(witness: MY_OTW_SECOND, ctx: &mut TxContext) {
        registry::add_record(
            witness,
            string::utf8(b"My awesome record"),
            ctx
        )
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        init(MY_OTW_SECOND {}, ctx);
    }
}

#[test_only]
module basics::one_time_witness_registryTests {
    use sui::test_scenario;
    use basics::one_time_witness_registry::{UniqueTypeRecord};
    use basics::my_otw_first::{Self, MY_OTW_FIRST};
    use basics::my_otw_second::{Self, MY_OTW_SECOND};

    #[test]
    fun test_add_record() {
        let owner = @0x1;
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        assert!(!test_scenario::has_most_recent_shared<UniqueTypeRecord<MY_OTW_FIRST>>(), 0);
        assert!(!test_scenario::has_most_recent_shared<UniqueTypeRecord<MY_OTW_SECOND>>(), 0);
        {
            let ctx = test_scenario::ctx(scenario);
            my_otw_first::init_for_test(ctx);
            my_otw_second::init_for_test(ctx);
        };
        // test_scenario::next_tx(scenario, owner);
        // {
        //     let otw_first = test_scenario::take_shared<UniqueTypeRecord<MY_OTW_FIRST>>(scenario);
        //     let otw_second = test_scenario::take_shared<UniqueTypeRecord<MY_OTW_SECOND>>(scenario);
        //     test_scenario::return_shared(otw_first);
        //     test_scenario::return_shared(otw_second);
        // };
        test_scenario::end(scenario_val);
        assert!(test_scenario::has_most_recent_shared<UniqueTypeRecord<MY_OTW_FIRST>>(), 0);
        assert!(test_scenario::has_most_recent_shared<UniqueTypeRecord<MY_OTW_SECOND>>(), 0);
    }
}