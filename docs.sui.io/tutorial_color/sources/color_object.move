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
}