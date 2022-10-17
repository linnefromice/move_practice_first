module tutorial_color::color_object {
    use sui::object;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Color {
        red: u8,
        green: u8,
        blue: u8,
    }

    struct ColorObject has key {
        id: object::UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        ColorObject {
            id: object::new(ctx),
            red,
            green,
            blue,
        }
    }

    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red = from_object.red;
        into_object.green = from_object.green;
        into_object.blue = from_object.blue;
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }

    #[test_only]
    use sui::test_scenario;
    #[test]
    fun test_create() {
        let owner = @0x111;
        let scenario = &mut test_scenario::begin(&owner);
        {
            let ctx = test_scenario::ctx(scenario);
            create(255, 0, 255, ctx);
        };
        let not_owner = @0x2;
        test_scenario::next_tx(scenario, &not_owner);
        {
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        };
        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            let (red, green, blue) = get_color(&object);
            assert!(red == 255, 0);
            assert!(green == 0, 0);
            assert!(blue == 255, 0);
            test_scenario::return_owned(scenario, object);
        }
    }
    #[test]
    fun test_copy_into() {
        let owner = @0x1;
        let scenario_val = test_scenario::begin(&owner);
        let scenario = &mut scenario_val;
        let (id1, id2) = {
            let ctx = test_scenario::ctx(scenario);
            create(255, 255, 255, ctx);
            let id1 = object::id_from_address(tx_context::last_created_object_id(ctx));
            create(0, 0, 0, ctx);
            let id2 = object::id_from_address(tx_context::last_created_object_id(ctx));
            (id1, id2)
        };
        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let obj2 = test_scenario::take_owned_by_id<ColorObject>(scenario, id2);
            let (red, green, blue) = get_color(&obj1);
            assert!(red == 255, 0);
            assert!(green == 255, 0);
            assert!(blue == 255, 0);

            copy_into(&obj2, &mut obj1);
            test_scenario::return_owned(scenario, obj1);
            test_scenario::return_owned(scenario, obj2);
        };
        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let (red, green, blue) = get_color(&obj1);
            assert!(red == 0, 0);
            assert!(green == 0, 0);
            assert!(blue == 0, 0);
            test_scenario::return_owned(scenario, obj1);
        };
    }
}