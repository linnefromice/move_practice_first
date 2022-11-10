#[test_only]
module various::table_test {
    use std::ascii;
    use std::type_name;
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::test_scenario;

    struct FINAL_FANTASY {}
    struct DRAGON_QUEST {}
    struct STAR_OCEAN {}
    struct CHRONO_TRIGGER {}

    #[test]
    fun test_table_and_type_name() {
        let owner = @0x1;
        let tc = test_scenario::begin(owner);
        let tc_mut = &mut tc;
        
        test_scenario::next_tx(tc_mut, owner);
        {
            let ctx = test_scenario::ctx(tc_mut);
            let table = table::new<ascii::String, u64>(ctx);
            transfer::transfer(table, owner);
        };
        test_scenario::next_tx(tc_mut, owner);
        {
            let table = test_scenario::take_from_address<Table<ascii::String, u64>>(tc_mut, owner);

            table::add(
                &mut table,
                *type_name::borrow_string(&type_name::get<FINAL_FANTASY>()),
                10
            );
            table::add(
                &mut table,
                *type_name::borrow_string(&type_name::get<DRAGON_QUEST>()),
                20
            );

            test_scenario::return_to_address(owner, table);
        };
        test_scenario::next_tx(tc_mut, owner);
        {
            let table = test_scenario::take_from_address<Table<ascii::String, u64>>(tc_mut, owner);

            assert!(table::length(&table) == 2, 0);
            assert!(*table::borrow(&table, *type_name::borrow_string(&type_name::get<FINAL_FANTASY>())) == 10, 0);
            assert!(*table::borrow(&table, *type_name::borrow_string(&type_name::get<DRAGON_QUEST>())) == 20, 0);
            assert!(!table::contains(&table, *type_name::borrow_string(&type_name::get<STAR_OCEAN>())), 0);
            assert!(!table::contains(&table, *type_name::borrow_string(&type_name::get<CHRONO_TRIGGER>())), 0);

            test_scenario::return_to_address(owner, table);
        };
        test_scenario::end(tc);
    }
}