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
}