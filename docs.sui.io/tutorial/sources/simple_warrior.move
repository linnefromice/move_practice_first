module tutorial::simple_warrior {
	use std::option::{Self, Option};
	use sui::object::{Self, UID};
	use sui::transfer;
	use sui::tx_context::{Self, TxContext};

	struct Sword has key, store {
		id: UID,
		strength: u8
	}

	struct Shield has key, store {
		id: UID,
		armor: u8
	}

	struct SimpleWarrior has key {
		id: UID,
		sword: Option<Sword>,
		shield: Option<Shield>
	}

	public entry fun create_sword(strength: u8, ctx: &mut TxContext) {
		let sword = Sword {
			id: object::new(ctx),
			strength
		};
		transfer::transfer(sword, tx_context::sender(ctx))
	}

	public entry fun create_shield(armor: u8, ctx: &mut TxContext) {
		let shield = Shield {
			id: object::new(ctx),
			armor
		};
		transfer::transfer(shield, tx_context::sender(ctx))
	}

	public entry fun create_warrior(ctx: &mut TxContext) {
		let obj = SimpleWarrior {
			id: object::new(ctx),
			sword: option::none(),
			shield: option::none()
		};
		transfer::transfer(obj, tx_context::sender(ctx))
	}

	public entry fun equip_sword(warrior: &mut SimpleWarrior, sword: Sword, ctx: &mut TxContext) {
		if (option::is_some(&warrior.sword)) {
			let old_sword = option::extract(&mut warrior.sword);
			transfer::transfer(old_sword, tx_context::sender(ctx));
		};
		option::fill(&mut warrior.sword, sword);
	}

	public entry fun equip_shield(warrior: &mut SimpleWarrior, shield: Shield, ctx: &mut TxContext) {
		if (option::is_some(&warrior.shield)) {
			let old_shield = option::extract(&mut warrior.shield);
			transfer::transfer(old_shield, tx_context::sender(ctx));
		};
		option::fill(&mut warrior.shield, shield);
	}

	public fun get_warrior(self: &SimpleWarrior): (bool, u8, bool, u8) {
		let is_equipped_sword = option::is_some(&self.sword);
		let is_equipped_shield = option::is_some(&self.shield);
		(
			is_equipped_sword,
			if (is_equipped_sword) option::borrow(&self.sword).strength else 0,
			is_equipped_shield,
			if (is_equipped_shield) option::borrow(&self.shield).armor else 0,
		)
	}
}

#[test_only]
module tutorial::simple_warriorTests {
	use std::option;
	use sui::test_scenario;
	use sui::object;
	use sui::tx_context;
	use tutorial::simple_warrior::{Self, SimpleWarrior, Sword, Shield};

	#[test]
	fun test_create_1() {
		let owner = @0x1;
		let scenario_val = test_scenario::begin(owner);
		let scenario = &mut scenario_val;
		{
			let ctx = test_scenario::ctx(scenario);
			simple_warrior::create_warrior(ctx);
			simple_warrior::create_sword(0, ctx);
			simple_warrior::create_shield(0, ctx);
		};
		test_scenario::end(scenario_val);
		let owner_warrior = test_scenario::most_recent_id_for_address<SimpleWarrior>(owner);
		assert!(option::is_some(&owner_warrior), 0);
		let owner_sword = test_scenario::most_recent_id_for_address<Sword>(owner);
		assert!(option::is_some(&owner_sword), 0);
		let owner_shield = test_scenario::most_recent_id_for_address<Shield>(owner);
		assert!(option::is_some(&owner_shield), 0);
		let not_owner_warrior = test_scenario::most_recent_id_for_address<SimpleWarrior>(@0x2);
		assert!(option::is_none(&not_owner_warrior), 0);
	}
	#[test]
	fun test_create_2() {
		let owner = @0x1;
		let scenario_val = test_scenario::begin(owner);
		let scenario = &mut scenario_val;
		let (id) = {
			let ctx = test_scenario::ctx(scenario);
			simple_warrior::create_warrior(ctx);
			object::id_from_address(tx_context::last_created_object_id(ctx))
		};
		test_scenario::next_tx(scenario, owner);
		{
			let obj = test_scenario::take_from_sender_by_id<SimpleWarrior>(scenario, id);
			let (is_equipped_sword, strength, is_equipped_shield, armor) = simple_warrior::get_warrior(&obj);
			assert!(!is_equipped_sword, 0);
			assert!(strength == 0, 0);
			assert!(!is_equipped_shield, 0);
			assert!(armor == 0, 0);
			test_scenario::return_to_sender(scenario, obj);
		};
		test_scenario::end(scenario_val);
	}
	#[test]
	fun test_equip() {
		let owner = @0x1;
		let scenario_val = test_scenario::begin(owner);
		let scenario = &mut scenario_val;
		{
			let ctx = test_scenario::ctx(scenario);
			simple_warrior::create_warrior(ctx);
			simple_warrior::create_sword(10, ctx);
			simple_warrior::create_shield(5, ctx);
		};
		test_scenario::next_tx(scenario, owner);
		{
			let warrior = test_scenario::take_from_address<SimpleWarrior>(scenario, owner);
			let sword = test_scenario::take_from_address<Sword>(scenario, owner);
			let shield = test_scenario::take_from_address<Shield>(scenario, owner);
			let ctx = test_scenario::ctx(scenario);
			simple_warrior::equip_sword(&mut warrior, sword, ctx);
			simple_warrior::equip_shield(&mut warrior, shield, ctx);
			test_scenario::return_to_sender(scenario, warrior);
		};
		test_scenario::next_tx(scenario, owner);
		{
			let obj = test_scenario::take_from_address<SimpleWarrior>(scenario, owner);
			let (is_equipped_sword, strength, is_equipped_shield, armor) = simple_warrior::get_warrior(&obj);
			assert!(is_equipped_sword, 0);
			assert!(strength == 10, 0);
			assert!(is_equipped_shield, 0);
			assert!(armor == 5, 0);
			test_scenario::return_to_sender(scenario, obj);
		};
		test_scenario::end(scenario_val);
	}
}