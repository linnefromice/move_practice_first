module tutorial_simple_warrior::simple_warrior {
	use sui::object::{Self, UID};
	use sui::transfer;
	use sui::tx_context::{Self, TxContext};

	struct SimpleWarrior has key {
		id: UID,
	}

	public entry fun create_warrior(ctx: &mut TxContext) {
		let obj = SimpleWarrior {
			id: object::new(ctx)
		};
		transfer::transfer(obj, tx_context::sender(ctx))
	}
}

#[test_only]
module tutorial_simple_warrior::simple_warriorTests {
	use std::option;
	use sui::test_scenario;
	use tutorial_simple_warrior::simple_warrior::{Self, SimpleWarrior};

	#[test]
	fun test_create() {
		let owner = @0x1;
		let scenario_val = test_scenario::begin(owner);
		let scenario = &mut scenario_val;
		{
			let ctx = test_scenario::ctx(scenario);
			simple_warrior::create_warrior(ctx);
		};
		test_scenario::end(scenario_val);
		let owner_warrior = test_scenario::most_recent_id_for_address<SimpleWarrior>(owner);
		assert!(option::is_some(&owner_warrior), 0);
		let not_owner_warrior = test_scenario::most_recent_id_for_address<SimpleWarrior>(@0x2);
		assert!(option::is_none(&not_owner_warrior), 0);
	}
}